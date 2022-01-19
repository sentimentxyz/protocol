// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRateModel {
    function getBorrowRate(uint deposits, uint borrows, uint reserves) external pure returns (uint);
}