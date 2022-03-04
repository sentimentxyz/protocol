// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRiskEngine {
    function getBorrows(address account) external returns (uint);
    function getBalance(address account) external view returns (uint);
    function isAccountHealthy(address account) external returns (bool);
    function isBorrowAllowed(address account, address token, uint value)
        external returns (bool);
    function isWithdrawAllowed(address account, address token, uint value)
        external returns (bool);
}