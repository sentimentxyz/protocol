// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";

abstract contract PriceFeedBase is Pausable {
    mapping(address => address) public priceFeed;

    event UpdateFeed(address indexed tokenAddr, address indexed feedAddr);

    function getPrice(address token) external view virtual returns (uint);

     // AdminOnly
    function setProxy(address token, address _priceFeed) external adminOnly {
        priceFeed[token] = _priceFeed;
        emit UpdateFeed(token, priceFeed[token]);
    }
}