// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Errors} from "../../utils/Errors.sol";
import {Helpers} from "../../utils/Helpers.sol";
import {IRateModel} from "../../interface/core/IRateModel.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract LEther is LToken {
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
    function deposit() public payable {
        _updateState();
        _mint(msg.sender, msg.value.div(exchangeRate));
    }

    function withdraw(uint value) public {
        _updateState();
        (bool success, ) = msg.sender.call{value: value}("");
        if(!success) revert Errors.ETHTransferFailure();
        _burn(msg.sender, value.div(exchangeRate));
    }

    // Account Manager Functions
    function lendTo(address account, uint value) public accountManagerOnly returns (bool) {
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        bool isFirstBorrow = (borrowBalanceFor[account].principal == 0);
        (bool success, ) = account.call{value: value}("");
        if(!success) revert Errors.ETHTransferFailure();
        totalBorrows += value;
        borrowBalanceFor[account].principal += value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address account, uint value) public accountManagerOnly returns (bool) {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        totalBorrows -= value;
        borrowBalanceFor[account].principal -= value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return (borrowBalanceFor[account].principal == 0);
    }

    function _getBalance() internal view override returns (uint) {
        return address(this).balance;
    }
    
    receive() external payable {}
}