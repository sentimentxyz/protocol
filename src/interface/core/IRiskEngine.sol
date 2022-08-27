// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IRiskEngine {
    function initDep() external;
    function getBorrows(address account) external view returns (uint);
    function getBalance(address account) external view returns (uint);
    function isAccountHealthy(address account) external view returns (bool);
    function isBorrowAllowed(address account, address token, uint amt)
        external view returns (bool);
    function isWithdrawAllowed(address account, address token, uint amt)
        external view returns (bool);
}