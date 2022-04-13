// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract LERC20 is LToken {
    using Helpers for address;
    using PRBMathUD60x18 for uint;
    
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals,
        address _underlying,
        address _registry,
        uint _initialExchangeRate
    ) 
        LToken(
            _name,
            _symbol,
            _decimals,
            _underlying,
            _registry,
            msg.sender,
            _initialExchangeRate
        ) {}

    // Lender Functions
    /// @param value underlying token amount to be deposited
    function deposit(uint value) external whenNotPaused {
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