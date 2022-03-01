// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUserRegistry {
    event UpdateAccountManagerAddress(address indexed accountManager);

    function getAccounts() external view returns(address[] memory);
    function addAccount(address account, address owner) external;
    function updateAccount(address account, address owner) external;
    function closeAccount(address account) external;
    function ownerFor(address account) external view returns (address);
    function accountsOwnedBy(address user) external view returns (address[] memory);
}