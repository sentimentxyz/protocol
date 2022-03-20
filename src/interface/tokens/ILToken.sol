// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ILToken {
    event ReservesRedeemed(address indexed treasury, uint value);

    function underlying() external view returns (address);
    function lendTo(address account, uint value) external returns (bool);
    function getBorrowBalance(address account) external view returns (uint);
    function collectFrom(address account, uint value) external returns (bool);
}