// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC4626 {
    function convertToAssets(uint256 shares) external view returns (uint256);
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}