// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IYVToken {
    function token() external view returns (ERC20);
    function getPricePerShare() external view returns (uint256);
    function decimals() external view returns (uint256);
}