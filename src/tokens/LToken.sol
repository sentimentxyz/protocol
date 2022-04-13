// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";


abstract contract LToken is Pausable, ERC20, ILToken {
    using PRBMathUD60x18 for uint;

    // Privileged addresses
    address public rateModel;
    address public underlying;
    address public accountManager;
    IRegistry public immutable registry;

    // Market State Variables
    uint public exchangeRate;
    uint public lastUpdated;
    uint public borrowIndex;
    uint public totalReserves;
    uint public totalBorrows;
    uint public reserveFactor;

    // Borrow accounting
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }
    mapping(address => BorrowSnapshot) public borrowBalanceFor;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _underlying,
        address _registry,
        address _admin,
        uint _initialExchangeRate
    ) 
        Pausable(_admin)
        ERC20(_name, _symbol, _decimals)
    {
        underlying = _underlying;
        exchangeRate = _initialExchangeRate * 1e18;
        borrowIndex = 1e18;
        registry = IRegistry(_registry);
    }

    function initialize(string calldata _rateModel) external adminOnly {
        rateModel = registry.addressFor(_rateModel);
        accountManager = registry.addressFor('ACCOUNT_MANAGER');
    }

    // Virtual Functions
    /// @notice transfers underlying token to given address
    function _transferUnderlying(address to, uint value) internal virtual;

    /// @notice Total amount of underlying assets held by this contract
    function _getBalance() internal view virtual returns (uint);

    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    // Account Manager Functions
    function lendTo(address account, uint value)
        external
        whenNotPaused
        accountManagerOnly
        returns (bool) 
    {
        if (block.number != lastUpdated) _updateState();
        bool isFirstBorrow = (borrowBalanceFor[account].principal == 0);
        _transferUnderlying(account, value);
        totalBorrows += value;
        borrowBalanceFor[account].principal += value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address account, uint value)
        external
        accountManagerOnly
        returns (bool)
    {
        if (block.number != lastUpdated) _updateState();
        totalBorrows -= value;
        borrowBalanceFor[account].principal -= value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return (borrowBalanceFor[account].principal == 0);
    }

    /// @param value ltoken amount to be withdrawn
    function withdraw(uint value) external {
        _updateState();
        _transferUnderlying(msg.sender, value.mul(exchangeRate));
        _burn(msg.sender, value);
    }

    // Utility Functions
    function updateState() external { _updateState(); }

    function getBorrowBalance(address account) external view returns (uint) {
        return (
            borrowBalanceFor[account].principal == 0
        ) ?
        0 : borrowBalanceFor[account].principal
            .mul(
                (lastUpdated == block.number) ?
                    borrowIndex : _getBorrowIndex(_getRateFactor())
            )
            .div(borrowBalanceFor[account].interestIndex);
    }

    function getExchangeRate() external view returns (uint) {
        if (lastUpdated == block.number) return exchangeRate;
        uint interestAccrued = totalBorrows.mul(_getRateFactor());
        return _getExchangeRate(
            (totalBorrows + interestAccrued),
            (totalReserves + interestAccrued.mul(reserveFactor))
        );
    }

    // Internal Accounting Functions
    // Rate Factor = Block Delta * Interest Rate Per Block
    function _getRateFactor() internal view returns (uint) {
        return (block.number - lastUpdated).fromUint()
            .mul(IRateModel(rateModel).getBorrowRatePerBlock(_getBalance(), totalBorrows, totalReserves));
    }

    function _getBorrowIndex(uint rateFactor) internal view returns (uint) {
        return borrowIndex.mul(1e18 + rateFactor);
    }

    // TODO Is there a way to update exchangeRate without checking for zero totalSupply?
    function _updateState() internal {
        if (lastUpdated == block.number) return;

        uint rateFactor = _getRateFactor();
        uint interestAccrued = totalBorrows.mul(rateFactor);

        // Store results
        borrowIndex = _getBorrowIndex(rateFactor);
        totalBorrows += interestAccrued;
        totalReserves += interestAccrued.mul(reserveFactor);
        exchangeRate = _getExchangeRate(totalBorrows, totalReserves);
        lastUpdated = block.number;
    }

    /// @notice Exchange Rate = (underlying balance + total borrow - total reserves) / total supply
    function _getExchangeRate(uint _totalBorrows,uint _totalReserves)
        internal
        view
        returns (uint)
    {
        return (totalSupply == 0) ? exchangeRate :
            (_getBalance() + _totalBorrows - _totalReserves).div(totalSupply);
    }

    /// @notice transfers underlying token to specified address
    /// @param treasury address to transfer underlying token
    /// @param value amount of underlying token to transfer
    function redeemReserves(address treasury, uint value) external adminOnly {
        _updateState();

        if (value == type(uint).max) value = totalReserves;
        
        totalReserves -= value;
        _transferUnderlying(treasury, value);
        emit ReservesRedeemed(treasury, value);

        exchangeRate = (totalSupply == 0) ? exchangeRate :
            (_getBalance() + totalBorrows - totalReserves).div(totalSupply);
    }
}