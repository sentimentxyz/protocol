// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "./utils/ERC4626.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/**
    @title Lending Token
    @notice Lending token with ERC4626 implementation
*/
contract LToken is Pausable, ERC4626, ILToken {
    using FixedPointMathLib for uint256;

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Utility variable to indicate if contract is initialized
    bool private initialized;

    /// @notice Registry
    IRegistry public registry;

    /// @notice Rate Model
    IRateModel public rateModel;

    /// @notice Account Manager
    address public accountManager;

    /// @notice Protocol treasury
    address public treasury;

    /// @notice Block number of when the state of the LToken was last updated
    uint public lastUpdated;

    /// @notice Total amount of borrows cached
    uint public borrows;

    /// @notice Borrow Index used for debt accounting cached
    uint public borrowIndex;

    /// @notice Borrow origination fee rate
    uint public borrowFeeRate;

    /// @notice Protocol Reserves earned as part of the spread
    /// @dev Unused for now
    uint public reserves;

    /// @notice Reserve factor
    /// @dev Unused for now
    uint public reserveFactor;

    struct BorrowData {
        uint index;
        uint balance;
    }

    /// @notice borrow balance and index of an account
    mapping (address => BorrowData) public borrowData;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract initialization function
        @dev Can only be invoked once
        @param _asset Underlying ERC20 token
        @param _name Name of LToken
        @param _symbol Symbol of LToken
        @param _registry Address of Registry
        @param _borrowFeeRate Borrow Fee
        @param _treasury Protocol treasury
    */
    function init(
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _borrowFeeRate,
        address _treasury
    ) external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        initPausable(msg.sender);
        initERC4626(_asset, _name, _symbol);
        registry = _registry;
        borrowFeeRate = _borrowFeeRate;
        treasury = _treasury;
        lastUpdated = block.number;
        borrowIndex = 1e18;
    }

    /**
        @notice Initializes external dependencies
        @param _rateModel Name of rate model contract
    */
    function initDep(string calldata _rateModel) external adminOnly {
        rateModel = IRateModel(registry.addressFor(_rateModel));
        accountManager = registry.addressFor('ACCOUNT_MANAGER');
    }

    /**
        @notice Lends a specified amount of underlying asset to an account
        @param account Address of account
        @param amt Amount of token to lend
        @return isFirstBorrow Returns if the account is borrowing the asset for
            the first time
    */
    function lendTo(address account, uint amt)
        external
        whenNotPaused
        accountManagerOnly
        returns (bool isFirstBorrow)
    {
        updateState();
        isFirstBorrow = (borrowData[account].balance == 0);
        borrowData[account].balance = getBorrowBalance(account) + amt;
        borrowData[account].index = borrowIndex;
        borrows += amt;
        uint fee = amt.mulWadDown(borrowFeeRate);
        asset.transfer(treasury, fee);
        asset.transfer(account, amt - fee);
        return isFirstBorrow;
    }

    /**
        @notice Collects a specified amount of underlying asset from an account
        @param account Address of account
        @param amt Amount of token to collect
        @return isDebtCleared returns true when debt is cleared
    */
    function collectFrom(address account, uint amt)
        external
        accountManagerOnly
        returns (bool)
    {
        borrowData[account].balance = getBorrowBalance(account) - amt;
        borrowData[account].index = borrowIndex;
        borrows -= amt;
        return (borrowData[account].balance == 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns total amount of underlying assets
            totalAssets = underlying balance + debt owed by borrowers
        @return totalAssets Total amount of underlying assets
    */
    function totalAssets() public view override returns (uint) {
        return asset.balanceOf(address(this)) +
            ((lastUpdated == block.number) ? borrows : getBorrows());
    }

    /// @notice Current total borrows owed to the pool
    function getBorrows() public view returns (uint) {
        return borrows.mulWadUp(1e18 + getRateFactor());
    }

    /// @notice Current borrow balance for a particular account
    function getBorrowBalance(address account) public view returns (uint) {
        uint balance = borrowData[account].balance;
        return (balance == 0) ? 0 :
            (borrowIndex.mulWadUp(1e18 + getRateFactor()))
            .divWadDown(borrowData[account].index)
            .mulWadUp(balance);
    }

    /// @notice Updates state of the lending pool
    function updateState() public {
        if (lastUpdated == block.number) return;
        uint rateFactor = 1e18 + getRateFactor();
        borrows = borrows.mulWadUp(rateFactor);
        borrowIndex = borrowIndex.mulWadUp(rateFactor);
        lastUpdated = block.number;
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @dev Rate Factor = Block Delta * Interest Rate Per Block
            Block Delta = Number of blocks since last update
    */
    function getRateFactor() internal view returns (uint) {
        uint blockDiff = block.number - lastUpdated;
        return (blockDiff == 0) ? 0 : (blockDiff * 1e18)
                .mulWadUp(rateModel.getBorrowRatePerBlock(
                        asset.balanceOf(address(this)),
                        borrows
                    )
                );
    }

    function beforeDeposit(uint, uint) internal override { updateState(); }
    function beforeWithdraw(uint, uint) internal override { updateState(); }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function setBorrowFee(uint _borrowFeeRate) external adminOnly {
        borrowFeeRate = _borrowFeeRate;
    }
}