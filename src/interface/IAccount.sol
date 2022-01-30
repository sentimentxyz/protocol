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
    function addAsset(address tokenAddr) external;
    function addBorrow(address tokenAddr) external;
    function removeAsset(address tokenAddr) external;
    function removeBorrow(address tokenAddr) external;
    function exec(address target, uint amt, bytes memory data) external returns (bool, bytes memory);
}
