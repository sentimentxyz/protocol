// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRateModel {
    function getBorrowRatePerBlock(
        uint liquidity,
        uint borrows,
        uint reserves
    ) external pure returns (uint);
}