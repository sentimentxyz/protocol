// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract LERC20 is LToken {
    using Helpers for address;
    using PRBMathUD60x18 for uint;
    
    constructor(
        bytes32 _name, 
        bytes32 _symbol, 
        uint8 _decimals,
        address _underlying,
        address _rateModel,
        address _accountManager,
        uint _initialExchangeRate
    ) LToken(
        msg.sender,
        _name,
        _symbol,
        _decimals,
        _underlying,
        _rateModel,
        _accountManager,
        _initialExchangeRate
    ) {}

    // Lender Functions
    /// @param value underlying token amount to be deposited
    function deposit(uint value) external {
        _updateState();
        underlying.safeTransferFrom(msg.sender, address(this), value);
        _mint(msg.sender, value.div(exchangeRate));
    }

    /// @param value ltoken amount to be withdrawn
    function withdraw(uint value) external {
        _updateState();
        underlying.safeTransfer(msg.sender, value.mul(exchangeRate));
        _burn(msg.sender, value);
    }

    // Account Manager Functions
    function lendTo(address accountAddr, uint value) external accountManagerOnly returns (bool) {
        if(block.number != lastUpdated) _updateState();
        bool isFirstBorrow = (borrowBalanceFor[accountAddr].principal == 0);
        underlying.safeTransfer(accountAddr, value);
        totalBorrows += value;
        borrowBalanceFor[accountAddr].principal += value;
        borrowBalanceFor[accountAddr].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address accountAddr, uint value) external accountManagerOnly returns (bool) {
        if(block.number != lastUpdated) _updateState();
        totalBorrows -= value;
        borrowBalanceFor[accountAddr].principal -= value;
        borrowBalanceFor[accountAddr].interestIndex = borrowIndex;
        return (borrowBalanceFor[accountAddr].principal == 0);
    }

    function _getBalance() internal view override returns (uint) {
        return underlying.balanceOf(address(this));
    }
}