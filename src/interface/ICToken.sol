// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICERC20 {
    function mint(uint mintAmount) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function redeemUnderlying(uint redeemTokens) external returns (uint);
}

interface ICEther {
    function mint() external payable;
    function exchangeRateStored() external view returns (uint);
    function redeemUnderlying(uint redeemTokens) external returns (uint);
}