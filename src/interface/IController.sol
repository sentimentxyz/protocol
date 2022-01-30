// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IController {
    function canCall(
        address target,
        bytes4 sig,
        bytes calldata data
    ) external returns (bool, address[] memory, address[] memory);
}