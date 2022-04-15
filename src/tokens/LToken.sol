// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "../utils/ERC4626.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";

contract LToken is Pausable, ERC4626, ILToken {
    using PRBMathUD60x18 for uint;

    bool initialized;

    IRegistry public registry;

    IRateModel public rateModel;
    address public accountManager;

    uint public reserves;
    uint public borrows;
    uint public reserveFactor;
    uint public lastUpdated;

    mapping (address => uint) public borrowsOf;

    constructor(
        ERC20 _asset,
        string memory _name, 
        string memory _symbol,
        IRegistry _registry,
        uint _reserveFactor
    ) Pausable(msg.sender) ERC4626(_asset, _name, _symbol) {
        registry = _registry;
        reserveFactor = _reserveFactor;
        asset = _asset;
    }

    function initialize(
        address _admin,
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _reserveFactor
    ) external override {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        admin = _admin;
        asset = _asset;
        registry = _registry;
        reserveFactor = _reserveFactor;
        name = _name;
        symbol = _symbol;
        decimals = asset.decimals();

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function initializeDependencies(string calldata _rateModel) external adminOnly {
        rateModel = IRateModel(registry.addressFor(_rateModel));
        accountManager = registry.addressFor('ACCOUNT_MANAGER');
    }

    function totalAssets() public view override returns (uint) {
        // delta - change in total assets due to accrued interest
        uint delta = (borrows == 0 || lastUpdated == block.number) ? 0
            : borrows.mul(getRateFactor()).mul(1e18 - reserveFactor);
        return asset.balanceOf(address(this)) + borrows - reserves + delta;
    }

    // Hooks
    function afterDeposit(uint, uint) internal override { updateState(); }
    function beforeWithdraw(uint, uint) internal override { updateState(); }


    // Account Manager Functions
    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function lendTo(address account, uint amt)
        external
        whenNotPaused
        accountManagerOnly
        returns (bool isFirstBorrow) 
    {
        updateState();
        isFirstBorrow = (borrowsOf[account] == 0);
        borrows += amt;
        borrowsOf[account] += convertToShares(amt);
        asset.transfer(account, amt);
        return isFirstBorrow;
    }

    function collectFrom(address account, uint amt)
        external
        accountManagerOnly
        returns (bool)
    {
        updateState();
        borrows -= amt;
        borrowsOf[account] -= convertToShares(amt);
        return (borrowsOf[account] == 0);
    }

    function getBorrowBalance(address account) external view returns (uint) {
        return previewRedeem(borrowsOf[account]);
    }

    // Internal Accounting Functions
    function updateState() public {
        if (lastUpdated == block.number) return;
        uint rateFactor = getRateFactor();
        uint interestAccrued = borrows.mul(rateFactor);
        borrows += interestAccrued;
        reserves += interestAccrued.mul(reserveFactor);
        lastUpdated = block.number;
    }

    // Rate Factor = Block Delta * Interest Rate Per Block
    // Block Delta = Number of blocks since last update
    function getRateFactor() internal view returns (uint) {
        return (block.number - lastUpdated).fromUint()
                .mul(rateModel.getBorrowRatePerBlock(
                    asset.balanceOf(address(this)), 
                    borrows,
                    reserves
                    )
                );
    }

    // Admin Functions
    function redeemReserves(address to, uint amt) external adminOnly {
        updateState();
        reserves -= amt;
        emit ReservesRedeemed(to, amt);
        asset.transfer(to, amt);
    }
}