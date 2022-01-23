// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccountManager {
    function openAccount() external;
    function closeAccount() external;
    function repay(address accountAddr, address tokenAddr, uint value) external;
    function LTokenAddressFor(address tokenAddr) external view returns (address);
    function borrow(address accountAddr, address tokenAddr, uint value) external;
    function deposit(address accountAddr, address tokenAddr, uint value) external;
    function withdraw(address accountAddr, address tokenAddr, uint value) external;
    function exec(address accountAddr, address targetAddr, bytes memory data) external;
    function approve(address accountAddr, address tokenAddr, address spenderAddr, uint value) external;
}
