// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "./utils/ERC4626.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";

/**
    @title Lending Token
    @notice Lending token with ERC4626 implementation
*/
contract LToken is Pausable, ERC4626 {
    using PRBMathUD60x18 for uint;

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

    /// @notice Total amount of reserves
    uint public reserves;

    /// @notice Total amount of borrows
    uint public borrows;

    /// @notice Reserve Factor
    uint public reserveFactor;

    /// @notice Block number of when the state of the LToken was last updated
    uint public lastUpdated;

    /// @notice Mapping of account to borrow amount
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
        @param _reserveFactor Reserve Factor
    */
    function init(
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _reserveFactor
    ) external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        initPausable(msg.sender);
        initERC4626(_asset, _name, _symbol);
        registry = _registry;
        reserveFactor = _reserveFactor;
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
        borrowsOf[account] += convertToShares(amt);
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
        borrows -= amt;
        borrowsOf[account] -= convertToShares(amt);
        return (borrowsOf[account] == 0);
    }

    /**
        @notice Returns Borrow balance of given account
        @param account Address of account
        @return borrowBalance Amount of underlying tokens borrowed
    */
    function getBorrowBalance(address account) external view returns (uint) {
        return previewRedeem(borrowsOf[account]);
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns total amount of underlying assets
            totalAssets = underlying balance + totalBorrows - totalReservers + delta
            delta = totalBorrows * RateFactor * (1e18 - reserveFactor)
        @return totalAssets Total amount of underlying assets
    */
    function totalAssets() public view override returns (uint) {
        uint delta = (borrows == 0 || lastUpdated == block.number) ? 0
            : borrows.mul(_getRateFactor()).mul(1e18 - reserveFactor);
        return asset.balanceOf(address(this)) + borrows - reserves + delta;
    }

    /// @notice Updates state of the lending pool
    function updateState() public {
        if (lastUpdated == block.number) return;
        uint rateFactor = _getRateFactor();
        uint interestAccrued = borrows.mul(rateFactor);
        borrows += interestAccrued;
        reserves += interestAccrued.mul(reserveFactor);
        lastUpdated = block.number;
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @dev Rate Factor = Block Delta * Interest Rate Per Block
            Block Delta = Number of blocks since last update
    */
    function _getRateFactor() internal view returns (uint) {
        return (block.number - lastUpdated).fromUint()
                .mul(rateModel.getBorrowRatePerBlock(
                        asset.balanceOf(address(this)),
                        borrows,
                        reserves
                    )
                );
    }

    function afterDeposit(uint, uint) internal override { updateState(); }
    function beforeWithdraw(uint, uint) internal override { updateState(); }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Transfers reserves from the LP to the specified address
        @dev Emits ReservesRedeemed(to, amt)
        @param to Recipient address
        @param amt Amount of token to transfer
    */
    function redeemReserves(address to, uint amt) external adminOnly {
        updateState();
        reserves -= amt;
        emit ReservesRedeemed(to, amt);
        asset.transfer(to, amt);
    }
}