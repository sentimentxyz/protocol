// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IRateModel} from "../interface/core/IRateModel.sol";

/**
    @title Linear Rate Model
    @notice Rate model contract used by Lending pools to calculate borrow rate
    per sec
    Forked from aave https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol
*/
contract LinearRateModel is IRateModel {
    using FixedPointMathLib for uint;

    uint public immutable baseRate;
    uint public immutable slope1;
    uint public immutable slope2;
    uint public immutable OPTIMAL_USAGE_RATIO;
    uint public immutable MAX_EXCESS_USAGE_RATIO;

    /// @notice Number of seconds per year
    uint immutable secsPerYear;

    /**
        @notice Contract constructor
        @param _baseRate default value = 0
        @param _slope1 default value = 40000000000000000
        @param _slope2 default value = 600000000000000000
        @param _optimalUsageRatio default value = 900000000000000000
        @param _maxExcessUsageRatio default value = 100000000000000000
        @param _secsPerYear secs in a year, default value = 31556952 * 1e18
    */
    constructor(
        uint _baseRate,
        uint _slope1,
        uint _slope2,
        uint _optimalUsageRatio,
        uint _maxExcessUsageRatio,
        uint _secsPerYear
    )
    {
        baseRate = _baseRate;
        slope1 = _slope1;
        slope2 = _slope2;
        OPTIMAL_USAGE_RATIO = _optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = _maxExcessUsageRatio;
        secsPerYear = _secsPerYear;
    }

    /**
        @notice Calculates Borrow rate per second
        @param liquidity total balance of the underlying asset in the pool
        @param totalDebt balance of underlying assets borrowed from the pool
        @return uint borrow rate per sec
    */
    function getBorrowRatePerSecond(
        uint liquidity,
        uint totalDebt
    )
        external
        view
        returns (uint)
    {
        uint utilization = _utilization(liquidity, totalDebt);

        if (utilization > OPTIMAL_USAGE_RATIO) {
            return (
                baseRate + slope1 + slope2.mulWadDown(
                    getExcessBorrowUsage(utilization)
                )
            ).divWadDown(secsPerYear);
        } else {
            return (
                baseRate + slope1.mulDivDown(utilization, OPTIMAL_USAGE_RATIO)
            ).divWadDown(secsPerYear);
        }
    }

    function getExcessBorrowUsage(uint utilization)
        internal
        view
        returns (uint)
    {
        return (utilization - OPTIMAL_USAGE_RATIO).divWadDown(
            MAX_EXCESS_USAGE_RATIO
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