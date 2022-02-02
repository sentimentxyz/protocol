// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUserRegistry {
    function getMarginAccounts(address owner) external returns (address[] memory);
    function addMarginAccount(address owner, address marginAccount) external;
    function removeMarginAccount(address owner, address marginAccount) external;
    function isValidOwner(address owner, address marginAccount) external returns (bool);
}