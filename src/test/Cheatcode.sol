// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICheatCode {
    function addr(uint sk) external returns (address addr);
    function startPrank(address sender, address origin) external;
    function stopPrank() external;
}