// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccountFactory {

    event AccountCreated(
        address indexed account,
        address indexed accountManager
    );

    function create(address accountManager) external returns (address);
}