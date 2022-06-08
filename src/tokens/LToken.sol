// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "./utils/ERC4626.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/**
    @title Lending Token
    @notice Lending token with ERC4626 implementation
*/
contract LToken is Pausable, ERC4626 {
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

    /// @notice Total amount of borrows
    uint public borrows;

    /// @notice Block number of when the state of the LToken was last updated
    uint public lastUpdated;

    /// @notice Protocol reserves
    uint public reserves;

    /// @notice Reserve factor
    uint public reserveFactor;

    /// @notice Total borrow shares minted
    uint public totalBorrowShares;

    /// @notice Mapping of account to borrow in terms of shares
    mapping (address => uint) public borrowsOf;

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
        @param _reserveFactor Borrow Fee
        @param _treasury Protocol treasury
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
        initialized = true;
        initPausable(msg.sender);
        initERC4626(_asset, _name, _symbol);
        registry = _registry;
        reserveFactor = _reserveFactor;
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
        isFirstBorrow = (borrowsOf[account] == 0);

        uint borrowShares;
        require((borrowShares = convertAssetToBorrowShares(amt)) != 0, "ZERO_ASSETS");
        totalBorrowShares += borrowShares;
        borrowsOf[account] += borrowShares;

        borrows += amt;
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
        uint borrowShares;
        require((borrowShares = convertAssetToBorrowShares(amt)) != 0, "ZERO_ASSETS");
        borrowsOf[account] -= borrowShares;
        totalBorrowShares -= borrowShares;

        borrows -= amt;
        return (borrowsOf[account] == 0);
    }

    /**
        @notice Returns Borrow balance of given account
        @param account Address of account
        @return borrowBalance Amount of underlying tokens borrowed
    */
    function getBorrowBalance(address account) external view returns (uint) {
        return convertBorrowSharesToAsset(borrowsOf[account]);
    }

    function getReserves() public view returns (uint) {
        return reserves + borrows.mulWadUp(getRateFactor())
        .mulWadUp(reserveFactor);
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns total amount of underlying assets
            totalAssets = underlying balance + totalBorrows + delta
            delta = totalBorrows * RateFactor
        @return totalAssets Total amount of underlying assets
    */
    function totalAssets() public view override returns (uint) {
        return asset.balanceOf(address(this)) + getBorrows() - getReserves();
    }

    function getBorrows() public view returns (uint) {
        return borrows + borrows.mulWadUp(getRateFactor());
    }

    /// @notice Updates state of the lending pool
    function updateState() public {
        if (lastUpdated == block.number) return;
        uint rateFactor = getRateFactor();
        uint interestAccrued = borrows.mulWadUp(rateFactor);
        borrows += interestAccrued;
        reserves += interestAccrued.mulWadUp(reserveFactor);
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
        return (block.number == lastUpdated) ?
            0 :
            ((block.number - lastUpdated)*1e18)
            .mulWadUp(
                rateModel.getBorrowRatePerBlock(
                    asset.balanceOf(address(this)),
                    borrows
                )
            );
    }

    function convertAssetToBorrowShares(uint amt) internal view returns (uint) {
        uint256 supply = totalBorrowShares;
        return supply == 0 ? amt : amt.mulDivUp(supply, getBorrows());
    }

    function convertBorrowSharesToAsset(uint debt) internal view returns (uint) {
        uint256 supply = totalBorrowShares;
        return supply == 0 ? debt : debt.mulDivDown(getBorrows(), supply);
    }

    function beforeDeposit(uint, uint) internal override { updateState(); }
    function beforeWithdraw(uint, uint) internal override { updateState(); }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function redeemReserves(uint amt) external adminOnly {
        updateState();
        reserves -= amt;
        emit ReservesRedeemed(treasury, amt);
        asset.transfer(treasury, amt);
    }
}