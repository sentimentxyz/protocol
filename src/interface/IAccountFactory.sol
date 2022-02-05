// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccountFactory {
    function create() external returns (address);
}