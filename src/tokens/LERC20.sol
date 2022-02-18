// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Helpers} from "../utils/Helpers.sol";
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

    function _getBalance() internal view override returns (uint) {
        return underlying.balanceOf(address(this));
    }

    function _transferUnderlying(address to, uint value) internal override {
        underlying.safeTransfer(to, value);
    }
}