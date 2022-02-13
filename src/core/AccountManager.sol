// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IRiskEngine} from "../interface/core/IRiskEngine.sol";
import {IUserRegistry} from "../interface/core/IUserRegistry.sol";
import {IController} from "../interface/controllers/IController.sol";
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";

contract AccountManager is Pausable, IAccountManager {
    using Helpers for address;

    IRiskEngine public riskEngine;
    IUserRegistry public userRegistry;
    IAccountFactory public accountFactory;
    
    address[] public inactiveAccounts;
    
    mapping(address => bool) public isCollateralAllowed; // tokenAddr => bool
    mapping(address => address) public LTokenAddressFor; // token => LToken
    mapping(address => address) public controllerAddrFor; // address => controller

    event AccountAssigned(address indexed accountAddr, address indexed ownerAddr);
    event AccountClosed(address indexed accountAddr, address indexed accountOwner);
    event AccountLiquidated(address indexed accountAddr, address indexed accountOwner);
    event Borrow(address indexed accountAddr, address indexed accountOwner, address indexed tokenAddr, uint value);
    event Repay(address indexed accountAddr, address indexed accountOwner, address indexed tokenAddr, uint value);
    event UpdateRiskEngineAddress(address indexed riskEngineAddr);
    event UpdateUserRegistryAddress(address indexed userRegistryAddr);
    event UpdateControllerAddress(address indexed contractAddr,address indexed controllerAddr);
    event UpdateAccountFactoryAddress(address indexed accountFactoryAddr);
    event UpdateLTokenAddress(address indexed tokenAddr, address indexed LTokenAddr);

    constructor(address _riskEngine, address _accountFactory, address _userRegistry) Pausable(msg.sender) {
        riskEngine = IRiskEngine(_riskEngine);
        accountFactory = IAccountFactory(_accountFactory);
        userRegistry = IUserRegistry(_userRegistry);
    }

    modifier onlyOwner(address account) {
        if(IAccount(account).owner() != msg.sender) revert Errors.AccountOwnerOnly();
        _;
    }

    function openAccount(address owner) public {
        address account;
        if(inactiveAccounts.length == 0) {
            account = accountFactory.create(address(this));
            IAccount(account).initialize(address(this));
        } else {
            account = inactiveAccounts[inactiveAccounts.length - 1];
            inactiveAccounts.pop();
        }
        IAccount(account).activateFor(owner);
        userRegistry.addAccount(account, owner);
        emit AccountAssigned(account, owner);
    }

    function closeAccount(address _account) public onlyOwner(_account) {
        IAccount account = IAccount(_account);
        if(account.hasNoDebt()) revert Errors.PendingDebt(); // TODO Refactor to OutstandingDebt
        account.sweepTo(msg.sender);
        account.deactivate();
        userRegistry.closeAccount(_account, msg.sender);
        inactiveAccounts.push(_account);
        emit AccountClosed(_account, msg.sender);
    }

    function depositEth(address account) external payable onlyOwner(account) {
        account.safeTransferETH(msg.value);
    }

    function withdrawETH(address account, uint value) public onlyOwner(account) {
        account.withdrawETH(msg.sender, value);
    }

    function deposit(
        address account, 
        address token,
        uint value
    ) 
        public onlyOwner(account) 
    {
        if(!isCollateralAllowed[token]) revert Errors.CollateralTypeRestricted();
        if(token.balanceOf(account) == 0) IAccount(account).addAsset(address(token));
        token.safeTransferFrom(msg.sender, account, value);
    }

    function withdraw(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account) 
    {
        if(!riskEngine.isWithdrawAllowed(account, token, value))
            revert Errors.RiskThresholdBreached();
        account.withdraw(msg.sender, token, value);
        if(token.balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    function borrow(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account)
    { 
        if(LTokenAddressFor[token] == address(0)) revert Errors.LTokenUnavailable();
        if(!riskEngine.isBorrowAllowed(account, token, value)) 
            revert Errors.RiskThresholdBreached();
        if(token != address(0) && token.balanceOf(account) == 0) 
            IAccount(account).addAsset(token);
        if(ILToken(LTokenAddressFor[token]).lendTo(account, value))
            IAccount(account).addBorrow(token);
        emit Borrow(account, msg.sender, token, value);
    }

    function repay(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account) 
    {
        if(LTokenAddressFor[token] == address(0)) revert Errors.LTokenUnavailable();
        _repay(account, token, value);
        emit Repay(account, msg.sender, token, value);
    }

    function liquidate(address account) public {
        if(!riskEngine.isLiquidatable(account)) revert Errors.AccountNotLiquidatable();
        _liquidate(account);
        emit AccountLiquidated(account, IAccount(account).owner());
    }

    function approve(
        address account, 
        address token,
        address spender, 
        uint value
    ) public onlyOwner(account) {
        account.safeApprove(token, spender, value);
    }

    function exec(
        address account, 
        address target,
        uint amt,
        bytes4 sig,
        bytes calldata data
    ) public onlyOwner(account) {
        bool isAllowed;
        address[] memory tokensIn;
        address[] memory tokensOut;
        
        address controller = controllerAddrFor[target];
        if(controller == address(0)) revert Errors.ControllerUnavailable();
        (isAllowed, tokensIn, tokensOut) = 
            IController(controller).canCall(target, sig, data);
        if(!isAllowed) revert Errors.FunctionCallRestricted();
        IAccount(account).exec(target, amt, bytes.concat(sig, data));
        _updateTokens(account, tokensIn, tokensOut);
        if(riskEngine.isLiquidatable(account)) revert Errors.RiskThresholdBreached();
    }

    function settle(address account) public onlyOwner(account) {
        address[] memory borrows = IAccount(account).getBorrows();
        for (uint i = 0; i < borrows.length; i++) {
            uint balance = borrows[i].balanceOf(account);
            if ( balance > 0 ) repay(account, borrows[i], balance);
        }
    }

    // Admin-Only
    function toggleCollateralState(address token) public adminOnly {
        isCollateralAllowed[token] = !isCollateralAllowed[token];
    }

    function setLTokenAddress(address token, address LToken) public adminOnly {
        LTokenAddressFor[token] = LToken;
        emit UpdateLTokenAddress(token, LToken);
    }

    function setRiskEngineAddress(address _riskEngine) public adminOnly {
        riskEngine = IRiskEngine(_riskEngine);
        emit UpdateRiskEngineAddress(address(riskEngine));
    }

    function setUserRegistryAddress(address _userRegistry) public adminOnly {
        userRegistry = IUserRegistry(_userRegistry);
        emit UpdateUserRegistryAddress(address(userRegistry));
    }

    function setControllerAddress(address target, address controller) public adminOnly {
        controllerAddrFor[target] = controller;
        emit UpdateControllerAddress(target, controller);
    }

    function setAccountFactoryAddress(address _accountFactory) public adminOnly {
        accountFactory = IAccountFactory(_accountFactory);
        emit UpdateAccountFactoryAddress(address(accountFactory));
    }

    // Internal Functions
    function _repay(address account, address token, uint value) internal {
        ILToken LToken = ILToken(LTokenAddressFor[token]);
        if(value == type(uint).max) value = LToken.currentBorrowBalance(account);

        if(token.isETH()) account.withdrawETH(address(LToken), value);
        else account.withdraw(address(LToken), token, value);
        
        if(LToken.collectFrom(account, value) && !token.isETH()) IAccount(account).removeBorrow(token);
        if (!token.isETH() && IERC20(token).balanceOf(account) == 0) IAccount(account).removeAsset(token);
    }

    function _updateTokens(address account, address[] memory tokensIn, address[] memory tokensOut) internal {
        uint tokensInLen = tokensIn.length;
        for(uint i = 0; i < tokensInLen; ++i) {
            if(tokensIn[i].balanceOf(account) == 0)
                IAccount(account).addAsset(tokensIn[i]);
        }
        
        uint tokensOutLen = tokensOut.length;
        for(uint i = 0; i < tokensOutLen; ++i) {
            if(tokensOut[i].balanceOf(account) == 0) 
                IAccount(account).removeAsset(tokensOut[i]);
        }
    }

    function _liquidate(address _account) internal {
        IAccount account = IAccount(_account);
        address[] memory accountBorrows = account.getBorrows();
        uint borrowLen = accountBorrows.length;

        for(uint i = 0; i < borrowLen; ++i) {
            // TODO Gas optimization by skipping removeAsset in repay
            _repay(_account, accountBorrows[i], type(uint).max);
        }
        account.sweepTo(msg.sender);
    }

    receive() external payable {}
}