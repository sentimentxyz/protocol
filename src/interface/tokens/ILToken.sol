// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ILToken {
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    event UpdateRateModelAddress(address indexed rateModel);
    event UpdateAccountManagerAddress(address indexed accountManager);

    function underlying() external view returns (address);
    function totalSupply() external view returns (uint);
    function lendTo(address account, uint value) external returns (bool);
    function currentBorrowBalance(address account) external returns (uint);
    function collectFrom(address account, uint value) external returns (bool);
    function storedBorrowBalance(address account) external view returns (uint);
}