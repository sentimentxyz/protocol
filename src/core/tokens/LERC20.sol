// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Helpers} from "../../utils/Helpers.sol";
import {IRateModel} from "../../interface/core/IRateModel.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract LERC20 is LToken {
    using Helpers for address;
    using PRBMathUD60x18 for uint;
    
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals,
        address _underlying,
        address _rateModel,
        address _accountManager,
        uint _initialExchangeRate
    )
    {
        // Token Metadata
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        underlying = _underlying;
        // Market State Variables
        exchangeRate = _initialExchangeRate * 1e18;
        borrowIndex = 1e18;
        // Privileged Addresses
        admin = msg.sender;
        rateModel = IRateModel(_rateModel);
        accountManager = _accountManager;
    }

    // Lender Functions
    function deposit(uint value) public {
        _updateState();
        underlying.safeTransferFrom(msg.sender, address(this), value);
        _mint(msg.sender, value.div(exchangeRate));
    }

    function withdraw(uint value) public {
        _updateState();
        underlying.safeTransfer(msg.sender, value);
        _burn(msg.sender, value.div(exchangeRate));
    }

    // Account Manager Functions
    function lendTo(address accountAddr, uint value) public accountManagerOnly returns (bool) {
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        bool isFirstBorrow = (borrowBalanceFor[accountAddr].principal == 0);
        underlying.safeTransfer(accountAddr, value);
        totalBorrows += value;
        borrowBalanceFor[accountAddr].principal += value;
        borrowBalanceFor[accountAddr].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address accountAddr, uint value) public accountManagerOnly returns (bool) {
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        totalBorrows -= value;
        borrowBalanceFor[accountAddr].principal -= value;
        borrowBalanceFor[accountAddr].interestIndex = borrowIndex;
        return (borrowBalanceFor[accountAddr].principal == 0);
    }

    function _getBalance() internal view override returns (uint) {
        return underlying.balanceOf(address(this));
    }
}