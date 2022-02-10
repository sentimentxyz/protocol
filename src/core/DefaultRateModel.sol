// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";

contract DefaultRateModel is IRateModel {
    using PRBMathUD60x18 for uint;

    // Constant coefficients with 18 decimals
    uint constant C1 = 1 * 1e17;  // 0.1
    uint constant C2 = 3 * 1e17;  // 0.3
    uint constant C3 = 35 * 1e17; // 3.5
    uint constant BLOCKS_PER_YEAR = 2102400 * 1e18; // TODO verify

    function getBorrowRate(uint deposits, uint borrows, uint reserves) public pure returns (uint) {
        uint util = _utilization(deposits, borrows, reserves); // U
        uint util32 = util.powu(32); // U^32
        uint util64 = util.powu(64); // U^64
        C3.mul((util.mul(C1) + util32.mul(C1) + util64.mul(C2)).div(BLOCKS_PER_YEAR));
        // return C3.mul((util.mul(C1) + util32.mul(C1) + util64.mul(C2)).div(BLOCKS_PER_YEAR));
        return 0; // TODO dummy
    }

    function _utilization(uint deposits, uint borrows, uint reserves) internal pure returns (uint) {
        return (deposits-reserves+borrows == 0) ? 0 : borrows.div(deposits-reserves+borrows);
    }
}