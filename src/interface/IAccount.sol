// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IAccount {
    function deactivate() external;
    function sweepTo(address toAddress) external;
    function activateFor(address ownerAddr) external;
    function hasNoDebt() external view returns (bool);
    function ownerAddr() external view returns (address);
    function initialize(address accountManagerAddr) external;
    function addToArray(bool flag, address tokenAddr) external;
    function removeFromArray(bool flag, address tokenAddr) external;
    function getArray(bool flag) external view returns (address[] memory);
    function exec(address target, uint amt, bytes memory data) external returns (bool, bytes memory);
}
