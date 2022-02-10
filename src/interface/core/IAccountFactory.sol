// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccountFactory {
    function create(address accountManager) external returns (address);
}