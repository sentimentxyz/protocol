// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUserRegistry {
    function addAccount(address account) external;
    function updateRegistry(address prevOwner, address newOwner) external;
    function getAccountsFor(address user) external view returns (address[] memory);
}