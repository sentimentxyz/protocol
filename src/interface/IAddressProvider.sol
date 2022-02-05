// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAddressProvider {
    function getAddress(bytes32 name) external view returns (address);
    function getLToken(address token) external view returns (address);
}