// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "./utils/ERC4626.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";

/**
    @title Lending Token
    @notice Lending token with ERC4626 implementation
*/
contract LToken is Pausable, ERC4626, ILToken {
    using FixedPointMathLib for uint;
    using SafeTransferLib for ERC20;

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

    /// @notice Timestamp of when the state of the LToken was last updated
    uint public lastUpdated;

    /// @notice Origination Fee
    uint public originationFee;

    /// @notice Total borrow shares minted
    uint public totalBorrowShares;

    /// @notice Mapping of account to borrow in terms of shares
    mapping (address => uint) public borrowsOf;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ReservesRedeemed(address indexed treasury, uint amt);

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
        @param _originationFee origination fee
        @param _treasury Protocol treasury
        @param _reserveShares Minimum amount of shares minted to zero address
    */
    function init(
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _originationFee,
        address _treasury,
        uint _reserveShares,
        uint _maxSupply
    ) external {
        if (initialized) revert Errors.ContractAlreadyInitialized();

        if (
            address(_asset) == address(0) ||
            address(_registry) == address(0) ||
            _treasury == address(0)
        ) revert Errors.ZeroAddress();

        initialized = true;
        initPausable(msg.sender);
        initERC4626(_asset, _name, _symbol, _reserveShares, _maxSupply);
        registry = _registry;
        originationFee = _originationFee;
        treasury = _treasury;
    }

    /**
        @notice Initializes external dependencies
        @param _rateModel Name of rate model contract
    */
    function initDep(string calldata _rateModel) external adminOnly {
        rateModel = IRateModel(registry.getAddress(_rateModel));
        accountManager = registry.getAddress('ACCOUNT_MANAGER');
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
        require((borrowShares = convertAssetToBorrowShares(amt)) != 0, "ZERO_BORROW_SHARES");
        totalBorrowShares += borrowShares;
        borrowsOf[account] += borrowShares;

        borrows += amt;

        uint fee = amt.mulDivDown(originationFee, 10 ** decimals);
        asset.safeTransfer(treasury, fee);
        asset.safeTransfer(account, amt - fee);
        
        return isFirstBorrow;
    }

    /**
        @notice Collects a specified amount of underlying asset from an account
        @param account Address of account
        @param amt Amount of token to collect
        @return bool Returns true if account has no debt
    */
    function collectFrom(address account, uint amt)
        external
        accountManagerOnly
        returns (bool)
    {
        uint borrowShares;
        require((borrowShares = convertAssetToBorrowShares(amt)) != 0, "ZERO_BORROW_SHARES");
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
        return asset.balanceOf(address(this)) + getBorrows();
    }

    function getBorrows() public view returns (uint) {
        return borrows + borrows.mulWadUp(getRateFactor());
    }

    /// @notice Updates state of the lending pool
    function updateState() public {
        if (lastUpdated == block.timestamp) return;
        uint rateFactor = getRateFactor();
        uint interestAccrued = borrows.mulWadUp(rateFactor);
        borrows += interestAccrued;
        lastUpdated = block.timestamp;
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @dev Rate Factor = Timestamp Delta * 1e18 (Scales timestamp delta to 18 decimals) * Interest Rate Per Block
            Timestamp Delta = Number of seconds since last update
    */
    function getRateFactor() internal view returns (uint) {
        return (block.timestamp == lastUpdated) ?
            0 :
            ((block.timestamp - lastUpdated)*1e18)
            .mulWadUp(
                rateModel.getBorrowRatePerSecond(
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

    function updateOriginationFee(uint _originationFee) external adminOnly {
        originationFee = _originationFee;
    }

    function updateMaxSupply(uint _maxSupply) external adminOnly {
        maxSupply = _maxSupply;
    }
}