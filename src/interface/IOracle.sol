// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IOracle {
    function getPrice(address tokenAddr) external view returns (uint);
}