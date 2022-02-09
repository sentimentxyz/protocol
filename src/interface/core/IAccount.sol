// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccount {
    function deactivate() external;
    function sweepTo(address toAddress) external;
    function activateFor(address owner) external;
    function hasNoDebt() external view returns (bool);
    function owner() external view returns (address);
    function initialize(address accountManager) external;
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function addAsset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function removeBorrow(address token) external;
    function exec(address target, uint amt, bytes memory data) payable external returns (bool, bytes memory);
}
