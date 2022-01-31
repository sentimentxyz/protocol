// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/Errors.sol";
import "./interface/IERC20.sol";
import "./interface/ILToken.sol";
import "./interface/IAccount.sol";
import "./interface/IRiskEngine.sol";
import "./interface/IController.sol";
import "./utils/SafeERC20.sol";
import "./interface/IUserRegistry.sol";
import "./interface/IAccountFactory.sol";

contract AccountManager {
    using SafeERC20 for IERC20;

    address public admin;
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

    constructor(address _riskEngine, address _accountFactory, address _userRegistry) {
        admin = msg.sender;
        riskEngine = IRiskEngine(_riskEngine);
        accountFactory = IAccountFactory(_accountFactory);
        userRegistry = IUserRegistry(_userRegistry);
    }

    modifier onlyOwner(address account) {
        if(IAccount(account).owner() != msg.sender) revert Errors.AccountOwnerOnly();
        _;
    }

    modifier onlyAdmin() {
        if(admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function openAccount(address owner) public {
        address account;
        if(inactiveAccounts.length == 0) {
            account = accountFactory.create(address(this));
        } else {
            account = inactiveAccounts[inactiveAccounts.length - 1];
            inactiveAccounts.pop();
        }
        IAccount(account).activateFor(owner);
        userRegistry.addMarginAccount(owner, account);
        emit AccountAssigned(account, owner);
    }

    function closeAccount(address _account) public onlyOwner(_account) {
        IAccount account = IAccount(_account);
        if(account.hasNoDebt()) revert Errors.PendingDebt();
        account.sweepTo(msg.sender);
        account.deactivate();
        userRegistry.removeMarginAccount(msg.sender, address(account));
        inactiveAccounts.push(address(account));
        emit AccountClosed(address(account), msg.sender);
    }

    function depositEth(address account) external payable onlyOwner(account) {
        (bool success, ) = account.call{value: msg.value}("");
        if(!success) revert Errors.ETHTransferFailure();
    }

    function withdrawEth(address account, uint value) public onlyOwner(account) {
        (bool success, ) = IAccount(account).exec(msg.sender, value, new bytes(0));
        if(!success) revert Errors.ETHTransferFailure();
    }

    function deposit(
        address account, 
        address token,
        uint value
    ) 
        public onlyOwner(account) 
    {
        if(!isCollateralAllowed[token]) revert Errors.CollateralTypeRestricted();
        if(IERC20(token).balanceOf(account) == 0) IAccount(account).addAsset(address(token));
        IERC20(token).safeTransferFrom(msg.sender, account, value);
    }

    function withdraw(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account) 
    {
        // TODO Add custom error after changing behavior of hasNoDebt() so that 
        // there is a way to execute this without always running isWithdrawAllowed
        require(IAccount(account).hasNoDebt() ||
            riskEngine.isWithdrawAllowed(account, token, value),
            "AccMgr/withdraw: Risky");
        
        (bool success, bytes memory data) = IAccount(account).exec(token, 0, 
                abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
        
        if(IERC20(token).balanceOf(account) == 0)
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
        if(token != address(0) && IERC20(token).balanceOf(account) == 0) 
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
        (bool success, bytes memory data) = IAccount(account).exec(token, 0, 
            abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED"); // TODO Refactor using custom errors
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
            uint balance = IERC20(borrows[i]).balanceOf(account);
            if ( balance > 0 ) repay(account, borrows[i], balance);
        }
    }

    // Admin-Only
    function toggleCollateralState(address token) public onlyAdmin {
        isCollateralAllowed[token] = !isCollateralAllowed[token];
    }

    function setLTokenAddress(address token, address LToken) public onlyAdmin {
        LTokenAddressFor[token] = LToken;
        emit UpdateLTokenAddress(token, LToken);
    }

    function setRiskEngineAddress(address _riskEngine) public onlyAdmin {
        riskEngine = IRiskEngine(_riskEngine);
        emit UpdateRiskEngineAddress(address(riskEngine));
    }

    function setUserRegistryAddress(address _userRegistry) public onlyAdmin {
        userRegistry = IUserRegistry(_userRegistry);
        emit UpdateUserRegistryAddress(address(userRegistry));
    }

    function setControllerAddress(address target, address controller) public onlyAdmin {
        controllerAddrFor[target] = controller;
        emit UpdateControllerAddress(target, controller);
    }

    function setAccountFactoryAddress(address _accountFactory) public onlyAdmin {
        accountFactory = IAccountFactory(_accountFactory);
        emit UpdateAccountFactoryAddress(address(accountFactory));
    }

    // Internal Functions
    function _repay(address account, address token, uint value) internal {
        ILToken LToken = ILToken(LTokenAddressFor[token]);
        bool isEth = token == address(0);
        if(value == type(uint).max) value = LToken.currentBorrowBalance(account);

        if(isEth) {
            (bool success, ) = IAccount(account).exec(address(LToken), value, new bytes(0));
            if(!success) revert Errors.ETHTransferFailure();
        }
        else {
             (bool success, bytes memory data) = IAccount(account).exec(token, 0, 
                abi.encodeWithSelector(IERC20.transfer.selector, address(LToken), value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED"); // TODO Refactor using custom errors
        }
        
        if(LToken.collectFrom(account, value) && !isEth) IAccount(account).removeBorrow(token);
        if (!isEth && IERC20(token).balanceOf(account) == 0) IAccount(account).removeAsset(token);
    }

    function _updateTokens(address account, address[] memory tokensIn, address[] memory tokensOut) internal {
        uint tokensInLen = tokensIn.length;
        for(uint i = 0; i < tokensInLen; ++i) {
            if(IERC20(tokensIn[i]).balanceOf(account) == 0)
                IAccount(account).addAsset(tokensIn[i]);
        }
        
        uint tokensOutLen = tokensOut.length;
        for(uint i = 0; i < tokensOutLen; ++i) {
            if(IERC20(tokensOut[i]).balanceOf(account) == 0) 
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