// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {IOracle} from "oracle/core/IOracle.sol";

interface IRiskEngine {
    function initDep() external;
    function getBorrows(address account) external returns (uint);
    function getBalance(address account) external returns (uint);
    function isAccountHealthy(address account) external returns (bool);
    function isBorrowAllowed(address account, address token, uint amt)
        external returns (bool);
    function isWithdrawAllowed(address account, address token, uint amt)
        external returns (bool);
    function oracle() external view returns (IOracle);
}