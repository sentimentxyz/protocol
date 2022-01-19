// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRiskEngine {
    function isLiquidatable(address accountAddr) external returns (bool);
    function currentAccountBorrows(address accountAddr) external returns (uint);
    function currentAccountBalance(address accountAddr) external view returns (uint);
    function isBorrowAllowed(address accountAddr, address tokenAddr, uint value) external returns (bool);
    function isWithdrawAllowed(address accountAddr, address tokenAddr, uint value) external returns (bool);
}