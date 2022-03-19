// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccountManager {
    event AccountAssigned(address indexed account, address indexed owner);
    event AccountClosed(address indexed account, address indexed owner);
    event AccountLiquidated(address indexed account, address indexed owner);
    event Repay(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint value
    );
    event Borrow(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint value
    );

    function initialize() external;
    function openAccount(address owner) external;
    function closeAccount(address account) external;
    function getInactiveAccounts() external view returns (address[] memory);
    function repay(address account, address token, uint value) external;
    function borrow(address account, address token, uint value) external;
    function deposit(address account, address token, uint value) external;
    function withdraw(address account, address token, uint value) external;
    function exec(
        address account,
        address target,
        uint amt,
        bytes calldata data
    ) external;
    function approve(
        address account,
        address token,
        address spender,
        uint value
    ) external;
}
