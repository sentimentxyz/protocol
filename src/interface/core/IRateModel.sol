// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRateModel {
    function getBorrowRatePerSecond(
        uint liquidity,
        uint borrows
    ) external view returns (uint);
}