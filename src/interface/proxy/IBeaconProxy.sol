// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBeaconProxy {
    function initProxy(address beacon, address admin) external;
}