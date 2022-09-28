// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILendingPoolAddressProvider {
    function getLendingPool() external view returns (address);
}