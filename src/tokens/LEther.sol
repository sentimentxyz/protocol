// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LToken} from "./LToken.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract LEther is LToken {
    using Helpers for address;
    using PRBMathUD60x18 for uint;
    
    constructor(
        uint _initialExchangeRate,
        address _registry
    ) 
        LToken(
            "LEther",
            "LETH",
            address(0),
            uint8(18),
            _initialExchangeRate,
            msg.sender,
            _registry
        )
    {}

    /// @notice deposit ETH in exchange for LETH
    function deposit() external payable {
        _updateState();
        _mint(msg.sender, msg.value.div(exchangeRate));
    }

    function _getBalance() internal view override returns (uint) {
        return address(this).balance;
    }

    function _transferUnderlying(address to, uint value) internal override {
        to.safeTransferEth(value);
    }
    
    receive() external payable {}
}