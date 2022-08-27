// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IBeacon {
    function implementation() external returns (address);
}