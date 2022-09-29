// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBeacon {
    function implementation() external returns (address);
}