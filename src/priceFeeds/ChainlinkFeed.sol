// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./PriceFeedBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkFeed is PriceFeedBase {
    constructor() {
        admin = msg.sender;
    }

    /// @dev Assume that the response has 18 decimals
    function getPrice(address token) external view override returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(priceFeed[token]).latestRoundData();
        return uint(price);
    }
}