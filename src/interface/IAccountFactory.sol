// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccountFactory {
    function openAccount(address accountManagerAddr) external returns (address);
}