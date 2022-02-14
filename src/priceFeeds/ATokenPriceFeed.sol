// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPriceFeed} from "../interface/priceFeeds/IPriceFeed.sol";
import {IAToken} from "../interface/priceFeeds/IAToken.sol";

contract ATokenPriceFeed is IPriceFeed {
    address public immutable priceFeedAggregator;

    constructor(address _priceFeedAggregator) {
        priceFeedAggregator = _priceFeedAggregator;
    }

    function getPrice(address aToken) external view returns (uint) {
        return IPriceFeed(priceFeedAggregator).getPrice(IAToken(aToken).UNDERLYING_ASSET_ADDRESS());
    }
}