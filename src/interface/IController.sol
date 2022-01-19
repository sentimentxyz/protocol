// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IController {
    function canCall(
        address targetAddr,
        bytes4 sig,
        bytes calldata data
    ) external returns (bool, address[] memory, address[] memory);
}