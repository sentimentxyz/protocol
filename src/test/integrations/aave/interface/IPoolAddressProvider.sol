// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPoolAddressProvider {
    function getPool() external view returns (address);
}