// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";
import {Errors} from "../utils/Errors.sol";

/**
    @title Default Rate Model
    @notice Rate model contract used by Lending pools to calculate borrow rate
    per block
*/
contract DefaultRateModel is IRateModel {
    using FixedPointMathLib for uint;

    /// @notice Constant coefficients with 18 decimals
    uint immutable c1;
    uint immutable c2;
    uint immutable c3;

    /// @notice Number of seconds per year
    uint immutable secsPerYear;

    uint constant SCALE = 1e18;

    /**
        @notice Contract constructor
        @param _c1 constant coefficient, default value = 1 * 1e17
        @param _c2 constant coefficient, default value = 3 * 1e17
        @param _c3 constant coefficient, default value = 35 * 1e17
        @param _secsPerYear secs in a year, default value = 31556952 * 1e18
    */
    constructor(uint _c1, uint _c2, uint _c3, uint _secsPerYear) {
        if (_c1 == 0 || _c2 == 0 || _c3 == 0 || _secsPerYear == 0)
            revert Errors.IncorrectConstructorArgs();
        c1 = _c1;
        c2 = _c2;
        c3 = _c3;
        secsPerYear = _secsPerYear;
    }

    /**
        @notice Calculates Borrow rate per second
        Borrow Rate Per Second =
        c3 * (util * c1 + util^32 * c1 + util^64 * c2) / secsPerYear
        where util = borrows / (liquidity + borrows)
        @param liquidity total balance of the underlying asset in the pool
        @param borrows balance of underlying assets borrowed from the pool
        @return uint borrow rate per sec
    */
    function getBorrowRatePerSecond(
        uint liquidity,
        uint borrows
    )
        external
        view
        returns (uint)
    {
        uint util = _utilization(liquidity, borrows);
        return c3.mulWadDown(
            (
                util.mulWadDown(c1)
                + util.rpow(32, SCALE).mulWadDown(c1)
                + util.rpow(64, SCALE).mulWadDown(c2)
            )
            .divWadDown(secsPerYear)
        );
    }

    function _utilization(uint liquidity, uint borrows)
        internal
        pure
        returns (uint)
    {
        uint totalAssets = liquidity + borrows;
        return (totalAssets == 0) ? 0 : borrows.divWadDown(totalAssets);
    }
}