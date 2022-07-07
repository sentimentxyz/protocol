// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {ERC4626} from "./utils/ERC4626.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";

/**
    @title Lending Token
    @notice Lending token with ERC4626 implementation
*/
contract LToken is Pausable, ERC4626, ILToken {
    using FixedPointMathLib for uint;

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

    /// @notice Protocol Treasury
    address public treasury;

    /// @notice unused
    uint public borrowFeeRate;

    /// @notice Total amount of borrows
    uint public borrows;

    /// @notice Cumulative borrow index
    uint public borrowIndex;

    /// @notice Total amount of reserves
    uint public reserves;

    /// @notice Reserve Factor
    uint public reserveFactor;

    /// @notice Block number of when the state of the LToken was last updated
    uint public lastUpdated;

    struct BorrowData {
        uint index;
        uint balance;
    }

    /// @notice Mapping of account to borrow amount
    mapping (address => BorrowData) public borrowData;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ReservesRedeemed(address indexed treasury, uint value);

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
        @param _reserveFactor Reserve Factor
        @param _treasury Protocol Treasury
    */
    function init(
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _reserveFactor,
        address _treasury
    ) external {
        if (initialized) revert Errors.ContractAlreadyInitialized();

        if (
            address(_asset) == address(0) ||
            address(_registry) == address(0) ||
            _treasury == address(0)
        ) revert Errors.ZeroAddress();

        initialized = true;
        initPausable(msg.sender);
        initERC4626(_asset, _name, _symbol);
        registry = _registry;
        reserveFactor = _reserveFactor;
        borrowIndex = 1e18;
        treasury = _treasury;
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
        borrows += amt;
        borrowData[account].balance = getBorrowBalance(account) + amt;
        borrowData[account].index = borrowIndex;
        asset.transfer(account, amt);
        return isFirstBorrow;
    }

    /**
        @notice Collects a specified amount of underlying asset from an account
        @param account Address of account
        @param amt Amount of token to collect
        @return isNotInDebt Returns if the account has pending borrows or not
    */
    function collectFrom(address account, uint amt)
        external
        accountManagerOnly
        returns (bool)
    {
        borrows -= amt;
        borrowData[account].balance = getBorrowBalance(account) - amt;
        borrowData[account].index = borrowIndex;
        return (borrowData[account].balance == 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns total amount of underlying assets
            totalAssets = liquidity + totalBorrows - totalReserves
        @return totalAssets Total amount of underlying assets
    */
    function totalAssets() public view override returns (uint) {
        return asset.balanceOf(address(this)) + getBorrows() - getReserves();
    }

    /// @notice Current total borrows owed to the pool
    function getBorrows() public view returns (uint) {
        return borrows.mulWadUp(1e18 + getRateFactor());
    }

    /// @notice Current total reserves in the pool
    function getReserves() public view returns (uint) {
        return reserves + borrows.mulWadUp(getRateFactor())
        .mulWadUp(reserveFactor);
    }

    /// @notice Updates state of the lending pool
    function updateState() public {
        if (lastUpdated == block.number) return;
        uint rateFactor = getRateFactor();
        uint interestAccrued = borrows.mulWadUp(rateFactor);
        borrows += interestAccrued;
        reserves += interestAccrued.mulWadUp(reserveFactor);
        borrowIndex += borrowIndex.mulWadUp(rateFactor);
        lastUpdated = block.number;
    }

    /**
        @notice Returns Borrow balance of given account
        @param account Address of account
        @return borrowBalance Amount of underlying tokens borrowed
    */
    function getBorrowBalance(address account) public view returns (uint) {
        uint balance = borrowData[account].balance;
        return (balance == 0) ? 0 :
            (borrowIndex.mulWadUp(1e18 + getRateFactor()))
            .divWadDown(borrowData[account].index)
            .mulWadUp(balance);
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @dev Rate Factor = Block Delta * Interest Rate Per Block
            Block Delta = Number of blocks since last update
    */
    function getRateFactor() internal view returns (uint) {
        uint blockDelta = block.number - lastUpdated;
        return (blockDelta == 0) ? 0 : (blockDelta * 1e18).mulWadUp(
                    rateModel.getBorrowRatePerBlock(
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

    /**
        @notice Transfers reserves from the LP to the treasury
        @dev Emits ReservesRedeemed(to, amt)
        @param amt Amount of token to transfer
    */
    function redeemReserves(uint amt) external adminOnly {
        updateState();
        reserves -= amt;
        emit ReservesRedeemed(treasury, amt);
        asset.transfer(treasury, amt);
    }

    function setBorrowFeeRate(uint _borrowFeeRate) external adminOnly {
        borrowFeeRate = _borrowFeeRate;
    }
}