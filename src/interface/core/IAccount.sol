// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAccount {
    function activate() external;
    function deactivate() external;
    function addAsset(address token) external;
    function addERC721Asset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function removeERC721Asset(address token) external;
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
    function getERC721Assets() external view returns (address[] memory);
    function exec(
        address target,
        uint amt,
        bytes calldata data
    ) external returns (bool, bytes memory);
}
