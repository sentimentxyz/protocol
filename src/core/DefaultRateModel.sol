// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";

/**
    @title Default Rate Model
    @notice Rate model contract used by Lending pools to calculate borrow rate
    per block
*/
contract DefaultRateModel is IRateModel {
    using PRBMathUD60x18 for uint;

    /// @notice Constant coefficients with 18 decimals
    uint immutable c1;
    uint immutable c2;
    uint immutable c3;

    /// @notice Number of blocks per year
    uint immutable blocksPerYear;

    /**
        @notice Contract constructor
        @param _c1 constant coefficient, default value = 1 * 1e17
        @param _c2 constant coefficient, default value = 3 * 1e17
        @param _c3 constant coefficient, default value = 35 * 1e17
        @param _blocksPerYear blocks in a year, default value = 2102400 * 1e18
    */
    constructor(uint _c1, uint _c2, uint _c3, uint _blocksPerYear) {
        c1 = _c1;
        c2 = _c2;
        c3 = _c3;
        blocksPerYear = _blocksPerYear;
    }

    /**
        @notice Calculates Borrow rate per block
        Borrow Rate Per Block =
        c3 * (util * c1 + util^32 * c1 + util^64 * c2) / blocksPerYear
        where util = borrows / (liquidity - reserves + borrows)
        @param liquidity total balance of the underlying asset in the pool
        @param borrows balance of underlying assets borrowed from the pool
        @param reserves balance of underlying assets reserved for the protocol
        @return uint borrow rate per block
    */
    function getBorrowRatePerBlock(
        uint liquidity,
        uint borrows,
        uint reserves
    )
        external
        view
        returns (uint)
    {
        uint util = _utilization(liquidity, borrows, reserves);
        return c3.mul(
            (
                util.mul(c1)
                + util.powu(32).mul(c1)
                + util.powu(64).mul(c2)
            )
            .div(blocksPerYear)
        );
    }

    function _utilization(
        uint liquidity,
        uint borrows,
        uint reserves
    )
        internal
        pure
        returns (uint)
    {
        return (liquidity - reserves + borrows == 0) ?
            0 : borrows.div(liquidity - reserves + borrows);
    }
}