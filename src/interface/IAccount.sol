// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IAccount {
    function deactivate() external;
    function ownerAddr() external view returns (address);
    function sweepTo(address toAddress) external;
    function addAsset(address tokenAddr) external;
    function addBorrow(address tokenAddr) external;
    function removeAsset(address tokenAddr) external;
    function activateFor(address ownerAddr) external;
    function removeBorrow(address tokenAddr) external;
    function hasNoDebt() external view returns (bool);
    function withdrawEth(address toAddr, uint value) external; 
    function assets() external view returns (address[] memory);
    function borrows() external view returns (address[] memory);
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function exec(address target, bytes memory data) external returns (bool);
    function swap(ISwapRouter.ExactInputSingleParams memory params) external;
    function withdraw(address toAddr, address tokenAddr, uint value) external;
    function repay(address LTokenAddr, address tokenAddr, uint value) external;
    function approve(address tokenAddr, address spenderAddr, uint value) external;
    function execPayable(address target, uint amt, bytes memory data) external returns (bool);
    function execComp(address cTokenAddr, address underlying, uint amt, bool isDeposit) external;
}
