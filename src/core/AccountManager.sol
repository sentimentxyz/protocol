// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

/**
    @title Account Manager
    @notice Sentiment Account Manager,
        All account interactions go via the account manager
*/
contract AccountManager is ReentrancyGuard, Pausable, IAccountManager {
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

    /// @notice List of inactive accounts per user
    mapping(address => address[]) public inactiveAccountsOf;

    /// @notice Mapping of collateral enabled tokens
    mapping(address => bool) public isCollateralAllowed;

    /// @notice Number of assets a sentiment account can hold - 1
    uint256 public assetCap;

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
        locked = 1;
        initialized = true;
        initPausable(msg.sender);
        registry = _registry;
    }

    /// @notice Initializes external dependencies
    function initDep() external adminOnly {
        riskEngine = IRiskEngine(registry.getAddress("RISK_ENGINE"));
        controller = IControllerFacade(registry.getAddress("CONTROLLER"));
        accountFactory = IAccountFactory(
            registry.getAddress("ACCOUNT_FACTORY")
        );
    }

    /**
        @notice Opens a new account for a user
        @dev Creates a new account if there are no inactive accounts otherwise
            reuses an already inactive account
            Emits AccountAssigned(account, owner) event
        @param owner Owner of the newly opened account
    */
    function openAccount(address owner)
        external
        nonReentrant
        whenNotPaused
        returns (address)
    {
        if (owner == address(0)) revert Errors.ZeroAddress();
        address account;
        uint256 length = inactiveAccountsOf[owner].length;
        if (length == 0) {
            account = accountFactory.create(address(this));
            IAccount(account).init(address(this));
            registry.addAccount(account, owner);
        } else {
            account = inactiveAccountsOf[owner][length - 1];
            inactiveAccountsOf[owner].pop();
            registry.updateAccount(account, owner);
        }
        IAccount(account).activate();
        emit AccountAssigned(account, owner);
        return account;
    }

    /**
        @notice Closes a specified account for a user
        @dev Account can only be closed when the account has no debt
            Emits AccountClosed(account, owner) event
        @param _account Address of account to be closed
    */
    function closeAccount(address _account)
        public
        nonReentrant
        onlyOwner(_account)
    {
        IAccount account = IAccount(_account);
        if (account.activationBlock() == block.number)
            revert Errors.AccountDeactivationFailure();
        if (!account.hasNoDebt()) revert Errors.OutstandingDebt();
        account.deactivate();
        registry.closeAccount(_account);
        inactiveAccountsOf[msg.sender].push(_account);
        account.sweepTo(msg.sender);
        emit AccountClosed(_account, msg.sender);
    }

    /**
        @notice Transfers Eth from owner to account
        @param account Address of account
    */
    function depositEth(address account)
        external
        payable
        nonReentrant
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
    function withdrawEth(address account, uint256 amt)
        external
        nonReentrant
        onlyOwner(account)
    {
        if (!riskEngine.isWithdrawAllowed(account, address(0), amt))
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
    function deposit(
        address account,
        address token,
        uint256 amt
    ) external nonReentrant whenNotPaused onlyOwner(account) {
        if (!isCollateralAllowed[token])
            revert Errors.CollateralTypeRestricted();
        if (IAccount(account).hasAsset(token) == false) {
            if (IAccount(account).getAssets().length > assetCap)
                revert Errors.MaxAssetCap();
            IAccount(account).addAsset(token);
        }
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
    function withdraw(
        address account,
        address token,
        uint256 amt
    ) external nonReentrant onlyOwner(account) {
        if (!riskEngine.isWithdrawAllowed(account, token, amt))
            revert Errors.RiskThresholdBreached();
        account.withdraw(msg.sender, token, amt);
        if (token.balanceOf(account) == 0) IAccount(account).removeAsset(token);
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
    function borrow(
        address account,
        address token,
        uint256 amt
    ) external nonReentrant whenNotPaused onlyOwner(account) {
        if (registry.LTokenFor(token) == address(0))
            revert Errors.LTokenUnavailable();
        if (IAccount(account).hasAsset(token) == false) {
            if (IAccount(account).getAssets().length > assetCap)
                revert Errors.MaxAssetCap();
            IAccount(account).addAsset(token);
        }
        if (ILToken(registry.LTokenFor(token)).lendTo(account, amt))
            IAccount(account).addBorrow(token);
        if (!riskEngine.isAccountHealthy(account))
            revert Errors.RiskThresholdBreached();
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
    function repay(
        address account,
        address token,
        uint256 amt
    ) public nonReentrant onlyOwner(account) {
        _repay(account, token, amt);
    }

    /**
        @notice Liquidates an account
        @dev Account can only be liquidated when it's unhealthy
            Emits AccountLiquidated(account, owner) event
        @param account Address of account
    */
    function liquidate(address account) external nonReentrant {
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
        uint256 amt
    ) external nonReentrant onlyOwner(account) {
        if (address(controller.controllerFor(spender)) == address(0))
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
        uint256 amt,
        bytes calldata data
    ) external nonReentrant onlyOwner(account) {
        bool isAllowed;
        address[] memory tokensIn;
        address[] memory tokensOut;
        (isAllowed, tokensIn, tokensOut) = controller.canCall(
            target,
            (amt > 0),
            data
        );
        if (!isAllowed) revert Errors.FunctionCallRestricted();
        _updateTokensIn(account, tokensIn);
        (bool success, ) = IAccount(account).exec(target, amt, data);
        if (!success)
            revert Errors.AccountInteractionFailure(account, target, amt, data);
        _updateTokensOut(account, tokensOut);
        if (IAccount(account).getAssets().length > assetCap + 1)
            revert Errors.MaxAssetCap();
        if (!riskEngine.isAccountHealthy(account))
            revert Errors.RiskThresholdBreached();
    }

    /**
        @notice Settles an account by repaying all the loans
        @param account Address of account
    */
    function settle(address account) external nonReentrant onlyOwner(account) {
        address[] memory borrows = IAccount(account).getBorrows();
        for (uint256 i; i < borrows.length; i++) {
            _repay(account, borrows[i], type(uint256).max);
        }
    }

    /**
        @notice Fetches inactive accounts of a user
        @param user Address of user
        @return address[] List of inactive accounts
    */
    function getInactiveAccountsOf(address user)
        external
        view
        returns (address[] memory)
    {
        return inactiveAccountsOf[user];
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    function _updateTokensIn(address account, address[] memory tokensIn)
        internal
    {
        uint256 tokensInLen = tokensIn.length;
        for (uint256 i; i < tokensInLen; ++i) {
            if (IAccount(account).hasAsset(tokensIn[i]) == false)
                IAccount(account).addAsset(tokensIn[i]);
        }
    }

    function _updateTokensOut(address account, address[] memory tokensOut)
        internal
    {
        uint256 tokensOutLen = tokensOut.length;
        for (uint256 i; i < tokensOutLen; ++i) {
            if (tokensOut[i].balanceOf(account) == 0)
                IAccount(account).removeAsset(tokensOut[i]);
        }
    }

    function _liquidate(address _account) internal {
        IAccount account = IAccount(_account);
        address[] memory accountBorrows = account.getBorrows();
        uint256 borrowLen = accountBorrows.length;

        ILToken LToken;
        uint256 amt;

        for (uint256 i; i < borrowLen; ++i) {
            address token = accountBorrows[i];
            LToken = ILToken(registry.LTokenFor(token));
            LToken.updateState();
            amt = LToken.getBorrowBalance(_account);
            token.safeTransferFrom(msg.sender, address(LToken), amt);
            LToken.collectFrom(_account, amt);
            account.removeBorrow(token);
            emit Repay(_account, msg.sender, token, amt);
        }
        account.sweepTo(msg.sender);
    }

    function _repay(
        address account,
        address token,
        uint256 amt
    ) internal {
        ILToken LToken = ILToken(registry.LTokenFor(token));
        if (address(LToken) == address(0)) revert Errors.LTokenUnavailable();
        LToken.updateState();
        if (amt == type(uint256).max) amt = LToken.getBorrowBalance(account);
        account.withdraw(address(LToken), token, amt);
        if (LToken.collectFrom(account, amt))
            IAccount(account).removeBorrow(token);
        if (IERC20(token).balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
        emit Repay(account, msg.sender, token, amt);
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

    /**
        @notice Set asset cap
        @param cap Number of assets
    */
    function setAssetCap(uint256 cap) external adminOnly {
        assetCap = cap - 1;
    }
}
