// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccountManager {
    function openAccount() external;
    function closeAccount() external;
    function repay(address account, address token, uint value) external;
    function LTokenAddressFor(address token) external view returns (address);
    function borrow(address account, address token, uint value) external;
    function deposit(address account, address token, uint value) external;
    function withdraw(address account, address token, uint value) external;
    function exec(address account, address target, bytes memory data) external;
    function approve(address account, address token, address spender, uint value) external;
}
