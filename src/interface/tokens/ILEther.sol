// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ILToken} from "./ILToken.sol";

interface ILEther is ILToken {
    function depositEth() external payable;
    function redeemEth(uint shares) external;
}