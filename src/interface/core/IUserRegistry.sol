// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUserRegistry {
    function addAccount(address account, address owner) external;
    function closeAccount(address account, address owner) external;
    function ownerFor(address account) external view returns (address);
    function accountsOwnedBy(address user) external view returns (address[] memory);
}