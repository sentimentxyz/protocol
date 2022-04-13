// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IRiskEngine} from "../interface/core/IRiskEngine.sol";
import {IControllerFacade} from "controller/core/IControllerFacade.sol";
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";

contract AccountManager is Pausable, IAccountManager {
    using Helpers for address;

    IRegistry public immutable registry;
    IRiskEngine public riskEngine;
    IControllerFacade public controller;
    IAccountFactory public accountFactory;
    
    address[] public inactiveAccounts;
    mapping(address => bool) public isCollateralAllowed;

    constructor(IRegistry _registry) Pausable(msg.sender) {
        registry = _registry;
    }

    function initialize() external adminOnly {
        riskEngine = IRiskEngine(registry.addressFor('RISK_ENGINE'));
        controller = IControllerFacade(registry.addressFor('CONTROLLER'));
        accountFactory = IAccountFactory(registry.addressFor('ACCOUNT_FACTORY'));
    }

    modifier onlyOwner(address account) {
        if (registry.ownerFor(account) != msg.sender)
            revert Errors.AccountOwnerOnly();
        _;
    }

    function openAccount(address owner) external whenNotPaused {
        address account;
        if (inactiveAccounts.length == 0) {
            account = accountFactory.create(address(this));
            IAccount(account).initialize(address(this));
            registry.addAccount(account, owner);
        } else {
            account = inactiveAccounts[inactiveAccounts.length - 1];
            inactiveAccounts.pop();
            registry.updateAccount(account, owner);
        }
        IAccount(account).activate();
        emit AccountAssigned(account, owner);
    }

    function closeAccount(address _account) public onlyOwner(_account) {
        IAccount account = IAccount(_account);
        if (account.activationBlock() == block.number)
            revert Errors.AccountDeactivationFailure();
        if (!account.hasNoDebt()) revert Errors.OutstandingDebt();
        account.sweepTo(msg.sender);
        registry.closeAccount(_account);
        inactiveAccounts.push(_account);
        emit AccountClosed(_account, msg.sender);
    }

    function depositEth(address account) 
        external
        payable
        whenNotPaused
        onlyOwner(account)
    {
        account.safeTransferEth(msg.value);
    }

    function withdrawEth(address account, uint value)
        external
        onlyOwner(account) 
    {
        if(!riskEngine.isWithdrawAllowed(account, address(0), value))
            revert Errors.RiskThresholdBreached();
        account.withdrawEth(msg.sender, value);
    }

    function deposit(address account, address token, uint value)
        external
        whenNotPaused
        onlyOwner(account)
    {
        if (!isCollateralAllowed[token]) 
            revert Errors.CollateralTypeRestricted();
        if (token.balanceOf(account) == 0)
            IAccount(account).addAsset(address(token));
        token.safeTransferFrom(msg.sender, account, value);
    }

    function withdraw(address account, address token, uint value)
        external
        onlyOwner(account) 
    {
        if (!riskEngine.isWithdrawAllowed(account, token, value))
            revert Errors.RiskThresholdBreached();
        account.withdraw(msg.sender, token, value);
        if (token.balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    function borrow(address account, address token, uint value)
        external
        whenNotPaused
        onlyOwner(account)
    { 
        if (registry.LTokenFor(token) == address(0))
            revert Errors.LTokenUnavailable();
        if (!riskEngine.isBorrowAllowed(account, token, value)) 
            revert Errors.RiskThresholdBreached();
        if (token != address(0) && token.balanceOf(account) == 0) 
            IAccount(account).addAsset(token);
        if (ILToken(registry.LTokenFor(token)).lendTo(account, value))
            IAccount(account).addBorrow(token);
        emit Borrow(account, msg.sender, token, value);
    }

    function repay(address account, address token, uint value) 
        public
        onlyOwner(account)
    {
        if (registry.LTokenFor(token) == address(0))
            revert Errors.LTokenUnavailable();
        _repay(account, token, value);
        emit Repay(account, msg.sender, token, value);
    }

    function liquidate(address account) external {
        if (riskEngine.isAccountHealthy(account))
            revert Errors.AccountNotLiquidatable();
        _liquidate(account);
        emit AccountLiquidated(account, registry.ownerFor(account));
    }

    function approve(
        address account, 
        address token,
        address spender, 
        uint value
    ) 
        external
        onlyOwner(account)
    {
        account.safeApprove(token, spender, value);
    }

    function exec(
        address account, 
        address target,
        uint amt,
        bytes calldata data
    )
        external
        onlyOwner(account) 
    {
        bool isAllowed;
        address[] memory tokensIn;
        address[] memory tokensOut;
        (isAllowed, tokensIn, tokensOut) = 
            controller.canCall(target, (amt > 0), data);
        if (!isAllowed) revert Errors.FunctionCallRestricted();
        _updateTokensIn(account, tokensIn);
        (bool success,) = IAccount(account).exec(target, amt, data);
        if (!success)
            revert Errors.AccountInteractionFailure(account, target, amt, data);
        _updateTokensOut(account, tokensOut);
        if (!riskEngine.isAccountHealthy(account))
            revert Errors.RiskThresholdBreached();
    }

    function settle(address account) external onlyOwner(account) {
        address[] memory borrows = IAccount(account).getBorrows();
        for (uint i = 0; i < borrows.length; i++) {
            uint balance;
            if (borrows[i] == address(0)) balance = account.balance;
            else balance = borrows[i].balanceOf(account);
            if ( balance > 0 ) repay(account, borrows[i], type(uint).max);
        }
    }

    function getInactiveAccounts() external view returns (address[] memory) {
        return inactiveAccounts;
    }

    // Internal Functions
    function _repay(address account, address token, uint value) internal {
        ILToken LToken = ILToken(registry.LTokenFor(token));
        if (value == type(uint).max) value = LToken.getBorrowBalance(account);

        if (token.isEth()) account.withdrawEth(address(LToken), value);
        else account.withdraw(address(LToken), token, value);
        
        if (LToken.collectFrom(account, value))
            IAccount(account).removeBorrow(token);
        if (!token.isEth() && IERC20(token).balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    function _updateTokensIn(address account, address[] memory tokensIn)
        internal
    {
        uint tokensInLen = tokensIn.length;
        for(uint i = 0; i < tokensInLen; ++i) {
            if (tokensIn[i].balanceOf(account) == 0)
                IAccount(account).addAsset(tokensIn[i]);
        }
    }

    function _updateTokensOut(address account, address[] memory tokensOut) 
        internal
    {
        uint tokensOutLen = tokensOut.length;
        for(uint i = 0; i < tokensOutLen; ++i) {
            if (tokensOut[i].balanceOf(account) == 0) 
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

    function toggleCollateralStatus(address token) external adminOnly {
        isCollateralAllowed[token] = !isCollateralAllowed[token];
    }

    receive() external payable {}
}