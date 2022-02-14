// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccountManager {
    event AccountAssigned(address indexed account, address indexed owner);
    event AccountClosed(address indexed account, address indexed owner);
    event AccountLiquidated(address indexed account, address indexed owner);
    event Repay(address indexed account, address indexed owner, address indexed token, uint value);
    event Borrow(address indexed account, address indexed owner, address indexed token, uint value);

    // AdminOnly Events
    event UpdateRiskEngineAddress(address indexed riskEngine);
    event UpdateUserRegistryAddress(address indexed userRegistry);
    event UpdateAccountFactoryAddress(address indexed accountFactory);
    event UpdateLTokenAddress(address indexed tokenAddr, address indexed LToken);
    event UpdateControllerAddress(address indexed contractAddr,address indexed controller);

    function openAccount(address owner) external;
    function closeAccount(address account) external;
    function repay(address account, address token, uint value) external;
    function LTokenAddressFor(address token) external view returns (address);
    function borrow(address account, address token, uint value) external;
    function deposit(address account, address token, uint value) external;
    function withdraw(address account, address token, uint value) external;
    function exec(address account, address target, uint amt, bytes4 sig, bytes calldata data) external;
    function approve(address account, address token, address spender, uint value) external;
}
