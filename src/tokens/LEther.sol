// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract LEther is LToken {
    using Helpers for address;
    using PRBMathUD60x18 for uint;
    
    constructor(
        address _rateModel, 
        address _accountManager, 
        uint _initialExchangeRate
    ) LToken(
        msg.sender,
        "LEther",
        "LETH",
        18,
        address(0),
        _rateModel,
        _accountManager,
        _initialExchangeRate
    ) {}

    // Lender Functions
    function deposit() external payable {
        _updateState();
        _mint(msg.sender, msg.value.div(exchangeRate));
    }

    /// @param value ltoken amount to be withdrawn
    function withdraw(uint value) external {
        _updateState();
        msg.sender.safeTransferETH(value.mul(exchangeRate));
        _burn(msg.sender, value);
    }

    // Account Manager Functions
    function lendTo(address account, uint value) external accountManagerOnly returns (bool) {
        if(block.number != lastUpdated) _updateState();
        bool isFirstBorrow = (borrowBalanceFor[account].principal == 0);
        (bool success, ) = account.call{value: value}("");
        if(!success) revert Errors.ETHTransferFailure();
        totalBorrows += value;
        borrowBalanceFor[account].principal += value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address account, uint value) external accountManagerOnly returns (bool) {
        if(block.number != lastUpdated) _updateState();
        totalBorrows -= value;
        borrowBalanceFor[account].principal -= value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return (borrowBalanceFor[account].principal == 0);
    }

    function _getBalance() internal view override returns (uint) {
        return address(this).balance;
    }

    function _redeemUnderlying(address to, uint value) internal override {
        to.safeTransferETH(value);
    }
    
    receive() external payable {}
}