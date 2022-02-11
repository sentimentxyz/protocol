// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPriceFeed} from "../interface/priceFeeds/IPriceFeed.sol";
import {IYVToken} from "../interface/priceFeeds/IYVToken.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract YVTokenPriceFeed is IPriceFeed {
    using PRBMathUD60x18 for uint;

    IPriceFeed public priceFeed;

    constructor (address _priceAggregator) {
        priceFeed = IPriceFeed(_priceAggregator);
    }

    function getPrice(address token) public view returns (uint) {
        return IYVToken(token).getPricePerShare()
                .mul(1e18)
                .mul(priceFeed.getPrice(address(IYVToken(token).token())))
                .div(10**IYVToken(token).decimals());
    }
}