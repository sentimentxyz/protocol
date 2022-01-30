// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";

interface ILToken {
    function underlying() external view returns (IERC20);
    function totalSupply() external view returns (uint);
    function lendTo(address account, uint value) external returns (bool);
    function currentBorrowBalance(address account) external returns (uint);
    function collectFrom(address account, uint value) external returns (bool);
    function storedBorrowBalance(address account) external view returns (uint);
}