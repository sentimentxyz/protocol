// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRiskEngine {
    function isLiquidatable(address account) external returns (bool);
    function currentAccountBorrows(address account) external returns (uint);
    function currentAccountBalance(address account) external view returns (uint);
    function isBorrowAllowed(address account, address token, uint value) external returns (bool);
    function isWithdrawAllowed(address account, address token, uint value) external returns (bool);
}