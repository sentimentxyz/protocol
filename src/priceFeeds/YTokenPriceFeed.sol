// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPriceFeed} from "../interface/priceFeeds/IPriceFeed.sol";
import {IYToken} from "../interface/priceFeeds/IYToken.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract YTokenPriceFeed is IPriceFeed {
    using PRBMathUD60x18 for uint;

    IPriceFeed public priceFeed;

    constructor (address _priceAggregator) {
        priceFeed = IPriceFeed(_priceAggregator);
    }

    function getPrice(address token) public view returns (uint price) {
        uint underlyingTokenPrice = priceFeed.getPrice(address(IYToken(token).token()));
        uint pricePerShare = IYToken(token).getPricePerShare();
        price = pricePerShare.mul(underlyingTokenPrice).div(10**IYToken(token).decimals());
    }
}