// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPriceFeed} from "../interface/priceFeeds/IPriceFeed.sol";
import {Ownable} from "../utils/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkFeed is IPriceFeed, Ownable {
    
    mapping(address => address) public priceFeed;

    event UpdateFeed(address indexed tokenAddr, address indexed feedAddr);

    constructor() Ownable(msg.sender) {}

    /// @dev Assume that the response has 18 decimals
    function getPrice(address token) external view override returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(priceFeed[token]).latestRoundData();
        return uint(price);
    }

     // AdminOnly
    function setFeed(address token, address _priceFeed) external adminOnly {
        priceFeed[token] = _priceFeed;
        emit UpdateFeed(token, priceFeed[token]);
    }
}