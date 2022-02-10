// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStableSwapPool {
    function coins(uint i) external view returns (address);
}