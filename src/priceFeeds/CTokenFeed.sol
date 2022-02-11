// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "../interface/tokens/IERC20.sol";
import {ICToken} from "../interface/priceFeeds/ICToken.sol";
import {IPriceFeed} from "../interface/priceFeeds/IPriceFeed.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract CTokenFeed is IPriceFeed {
    using PRBMathUD60x18 for uint;
    IPriceFeed public immutable priceFeedAggregator;

    constructor(address _priceFeedAggregator) {
        priceFeedAggregator = IPriceFeed(_priceFeedAggregator);
    }

    function getPrice(address cToken) external view returns (uint) {
        try ICToken(cToken).underlying() returns (address underlying) {
            return _cTokenExchangeRate(cToken, underlying).mul(_priceOfUnderlying(underlying));
        } catch {
            return _cTokenExchangeRate(cToken, address(0)).mul(_priceOfUnderlying(address(0))); // CEther
        }
    }

    /// @dev Scale exchangeRateStored to 18 decimals
    function _cTokenExchangeRate(address cToken, address underlying) internal view returns (uint) {
        return (underlying == address(0)) ? ICToken(cToken).exchangeRateStored().div(1e10) // CEther
            : ICToken(cToken).exchangeRateStored().mul(1e8).div(IERC20(underlying).decimals());
    }

    /// @dev Assume this returns an 18 decimal response
    function _priceOfUnderlying(address underlying) internal view returns (uint) {
        return priceFeedAggregator.getPrice(underlying);
    }
}