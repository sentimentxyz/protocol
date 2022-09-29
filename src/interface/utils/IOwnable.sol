// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOwnable {
    function admin() external returns (address);
}