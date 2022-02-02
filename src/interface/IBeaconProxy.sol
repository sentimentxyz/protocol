// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBeaconProxy {
    function initializeProxy(address beacon, address admin) external;
}