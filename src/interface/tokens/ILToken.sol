// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ILToken {
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    event UpdateRateModelAddress(address indexed rateModel);
    event UpdateAccountManagerAddress(address indexed accountManager);

    function totalSupply() external view returns (uint);
    function underlying() external view returns (address);
    function lendTo(address account, uint value) external returns (bool);
    function getBorrowBalance(address account) external view returns (uint);
    function collectFrom(address account, uint value) external returns (bool);
}