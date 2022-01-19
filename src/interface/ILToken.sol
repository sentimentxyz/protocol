// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILToken {
    function underlying() external view returns (address);
    function totalSupply() external view returns (uint);
    function lendTo(address accountAddr, uint value) external returns (bool);
    function currentBorrowBalance(address accountAddr) external returns (uint);
    function collectFrom(address accountAddr, uint value) external returns (bool);
    function storedBorrowBalance(address accountAddr) external view returns (uint);
}