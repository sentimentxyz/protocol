// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./PriceFeedBase.sol";

contract FeedAggregator is PriceFeedBase {
    address public immutable WETH_ADDR;

    constructor(address wethAddress) {
        admin = msg.sender;
        WETH_ADDR = wethAddress;
    }

    /// @dev Assume that the response has 18 decimals
    function getPrice(address token) external view override returns (uint) {
        if(token == address(0) || token == WETH_ADDR) return 1e18;
        if(priceFeed[token] == address(0)) revert Errors.PriceFeedUnavailable();
        return PriceFeedBase(priceFeed[token]).getPrice(token);
    }
}