// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUserRegistry {
    function getMarginAccounts() external view returns (address[] memory);
    function addMarginAccount(address marginAccount) external;
    function setMarginAccountOwner(address owner, address marginAccount) external;
    function isValidOwner(address owner, address marginAccount) external returns (bool);
}