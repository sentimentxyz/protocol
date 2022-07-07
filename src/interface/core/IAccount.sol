// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAccount {
    function activate() external;
    function addAsset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function sweepTo(address toAddress) external;
    function removeBorrow(address token) external;
    function init(address accountManager) external;
    function hasAsset(address) external returns (bool);
    function assets(uint) external returns (address);
    function hasNoDebt() external view returns (bool);
    function activationBlock() external view returns (uint);
    function accountManager() external view returns (address);
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function exec(
        address target,
        uint amt,
        bytes memory data
    ) payable external returns (bool, bytes memory);
}
