// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRateModel {
    function getBorrowRate(uint deposits, uint borrows, uint reserves) external pure returns (uint);
}