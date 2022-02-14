// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IZapController {
    function canCall(
        address sellToken,
        address buyToken
    ) external returns (bool, address[] memory, address[] memory);
}