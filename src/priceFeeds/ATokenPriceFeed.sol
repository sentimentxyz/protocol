// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interface/IPriceFeed.sol";
import "../interface/priceFeeds/IAToken.sol";

contract ATokenPriceFeed {
    address public immutable priceFeedAggregator;

    constructor(address _priceFeedAggregator) {
        priceFeedAggregator = _priceFeedAggregator;
    }

    function getPrice(address aToken) external view returns (uint) {
        IPriceFeed(priceFeedAggregator).getPrice(IAToken(aToken).UNDERLYING_ASSET_ADDRESS());
    }
}