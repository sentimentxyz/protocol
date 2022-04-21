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
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";
import {IControllerFacade} from "controller/core/IControllerFacade.sol";

/**
    @title Account Manager
    @notice Sentiment Account Manager,
        All account interactions go via the account manager
*/
contract AccountManager is Pausable, IAccountManager {
    using Helpers for address;

    /* -------------------------------------------------------------------------- */
    /*                               STATE_VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Utility variable to indicate if contract is initialized
    bool private initialized;

    /// @notice Registry
    IRegistry public registry;

    /// @notice Risk Engine
    IRiskEngine public riskEngine;

    /// @notice Controller Facade
    IControllerFacade public controller;

    /// @notice Account Factory
    IAccountFactory public accountFactory;

    /// @notice List of inactive accounts
    address[] public inactiveAccounts;

    /// @notice Mapping of collateral enabled tokens
    mapping(address => bool) public isCollateralAllowed;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier onlyOwner(address account) {
        if (registry.ownerFor(account) != msg.sender)
            revert Errors.AccountOwnerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Initializes contract
        @dev Can only be invoked once
        @param _registry Address of Registry
    */
    function init(IRegistry _registry) external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        initPausable(msg.sender);
        registry = _registry;
    }

    /// @notice Initializes external dependencies
    function initDep() external adminOnly {
        riskEngine = IRiskEngine(registry.addressFor('RISK_ENGINE'));
        controller = IControllerFacade(registry.addressFor('CONTROLLER'));
        accountFactory =
            IAccountFactory(registry.addressFor('ACCOUNT_FACTORY'));
    }

    /**
        @notice Opens a new account for a user
        @dev Creates a new account if there are no inactive accounts otherwise
            reuses an already inactive account
            Emits AccountAssigned(account, owner) event
        @param owner Owner of the newly opened account
    */
    function openAccount(address owner) external whenNotPaused {
        address account;
        if (inactiveAccounts.length == 0) {
            account = accountFactory.create(address(this));
            IAccount(account).init(address(this));
            registry.addAccount(account, owner);
        } else {
            account = inactiveAccounts[inactiveAccounts.length - 1];
            inactiveAccounts.pop();
            registry.updateAccount(account, owner);
        }
        IAccount(account).activate();
        emit AccountAssigned(account, owner);
    }

    /**
        @notice Closes a specified account for a user
        @dev Account can only be closed when the account has no debt
            Emits AccountClosed(account, owner) event
        @param _account Address of account to be closed
    */
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

    /**
        @notice Transfers Eth from owner to account
        @param account Address of account
    */
    function depositEth(address account)
        external
        payable
        whenNotPaused
        onlyOwner(account)
    {
        account.safeTransferEth(msg.value);
    }

    /**
        @notice Transfers Eth from the account to owner
        @dev Eth can only be withdrawn if the account remains healthy
            after withdrawal
        @param account Address of account
        @param amt Amount of Eth to withdraw
    */
    function withdrawEth(address account, uint amt)
        external
        onlyOwner(account)
    {
        if(!riskEngine.isWithdrawAllowed(account, address(0), amt))
            revert Errors.RiskThresholdBreached();
        account.withdrawEth(msg.sender, amt);
    }

    /**
        @notice Transfers a specified amount of token from the owner
            to the account
        @dev Token must be accepted as collateral by the protocol
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to deposit
    */
    function deposit(address account, address token, uint amt)
        external
        whenNotPaused
        onlyOwner(account)
    {
        if (!isCollateralAllowed[token])
            revert Errors.CollateralTypeRestricted();
        if (token.balanceOf(account) == 0)
            IAccount(account).addAsset(address(token));
        token.safeTransferFrom(msg.sender, account, amt);
    }

    /**
        @notice Transfers a specified amount of token from the account
            to the owner of the account
        @dev Amount of token can only be withdrawn if the account remains healthy
            after withdrawal
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to withdraw
    */
    function withdraw(address account, address token, uint amt)
        external
        onlyOwner(account)
    {
        if (!riskEngine.isWithdrawAllowed(account, token, amt))
            revert Errors.RiskThresholdBreached();
        account.withdraw(msg.sender, token, amt);
        if (token.balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    /**
        @notice Transfers a specified amount of token from the LP to the account
        @dev Specified token must have a LP
            Account must remain healthy after the borrow, otherwise tx is reverted
            Emits Borrow(account, msg.sender, token, amount) event
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to borrow
    */
    function borrow(address account, address token, uint amt)
        external
        whenNotPaused
        onlyOwner(account)
    {
        if (registry.LTokenFor(token) == address(0))
            revert Errors.LTokenUnavailable();
        if (!riskEngine.isBorrowAllowed(account, token, amt))
            revert Errors.RiskThresholdBreached();
        if (token.balanceOf(account) == 0) IAccount(account).addAsset(token);
        if (ILToken(registry.LTokenFor(token)).lendTo(account, amt))
            IAccount(account).addBorrow(token);
        emit Borrow(account, msg.sender, token, amt);
    }

    /**
        @notice Transfers a specified amount of token from the account to the LP
        @dev Specified token must have a LP
            Emits Repay(account, msg.sender, token, amount) event
        @param account Address of account
        @param token Address of token
        @param amt Amount of token to borrow
    */
    function repay(address account, address token, uint amt)
        public
        onlyOwner(account)
    {
        if (registry.LTokenFor(token) == address(0))
            revert Errors.LTokenUnavailable();
        _repay(account, token, amt);
        emit Repay(account, msg.sender, token, amt);
    }

    /**
        @notice Liquidates an account
        @dev Account can only be liquidated when it's unhealthy
            Emits AccountLiquidated(account, owner) event
        @param account Address of account
    */
    function liquidate(address account) external {
        if (riskEngine.isAccountHealthy(account))
            revert Errors.AccountNotLiquidatable();
        _liquidate(account);
        emit AccountLiquidated(account, registry.ownerFor(account));
    }

    /**
        @notice Gives a spender approval to spend a given amount of token from
            the account
        @dev Spender must have a controller in controller facade
        @param account Address of account
        @param token Address of token
        @param spender Address of spender
        @param amt Amount of token
    */
    function approve(
        address account,
        address token,
        address spender,
        uint amt
    )
        external
        onlyOwner(account)
    {
        if(address(controller.controllerFor(spender)) == address(0))
            revert Errors.FunctionCallRestricted();
        account.safeApprove(token, spender, amt);
    }

    /**
        @notice A general function that allows the owner to perform specific interactions
            with external protocols for their account
        @dev Target must have a controller in controller facade
        @param account Address of account
        @param target Address of contract to transact with
        @param amt Amount of Eth to send to the target contract
        @param data Encoded sig + params of the function to transact with in the
            target contract
    */
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

    /**
        @notice Settles an account by repaying all the loans
        @param account Address of account
    */
    function settle(address account) external onlyOwner(account) {
        address[] memory borrows = IAccount(account).getBorrows();
        for (uint i; i < borrows.length; i++) {
            uint balance;
            if (borrows[i] == address(0)) balance = account.balance;
            else balance = borrows[i].balanceOf(account);
            if ( balance > 0 ) repay(account, borrows[i], type(uint).max);
        }
    }

    /**
        @notice Returns a list of inactive accounts
        @return inactiveAccounts List of inactive Accounts
    */
    function getInactiveAccounts() external view returns (address[] memory) {
        return inactiveAccounts;
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    function _repay(address account, address token, uint value) internal {
        ILToken LToken = ILToken(registry.LTokenFor(token));
        if (value == type(uint).max) value = LToken.getBorrowBalance(account);
        account.withdraw(address(LToken), token, value);
        if (LToken.collectFrom(account, value))
            IAccount(account).removeBorrow(token);
        if (IERC20(token).balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    function _updateTokensIn(address account, address[] memory tokensIn)
        internal
    {
        uint tokensInLen = tokensIn.length;
        for(uint i; i < tokensInLen; ++i) {
            if (tokensIn[i].balanceOf(account) == 0)
                IAccount(account).addAsset(tokensIn[i]);
        }
    }

    function _updateTokensOut(address account, address[] memory tokensOut)
        internal
    {
        uint tokensOutLen = tokensOut.length;
        for(uint i; i < tokensOutLen; ++i) {
            if (tokensOut[i].balanceOf(account) == 0)
                IAccount(account).removeAsset(tokensOut[i]);
        }
    }

    function _liquidate(address _account) internal {
        IAccount account = IAccount(_account);
        address[] memory accountBorrows = account.getBorrows();
        uint borrowLen = accountBorrows.length;

        for(uint i; i < borrowLen; ++i) {
            _repay(_account, accountBorrows[i], type(uint).max);
        }
        account.sweepTo(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Toggle collateral status of a token
        @param token Address of token
    */
    function toggleCollateralStatus(address token) external adminOnly {
        isCollateralAllowed[token] = !isCollateralAllowed[token];
    }

    receive() external payable {}
}