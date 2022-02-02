// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/Errors.sol";
import "../interface/IPriceFeed.sol";


contract FeedAggregator {
    address public admin;
    address public immutable WETH_ADDR;
    mapping(address => address) public priceFeed;

    event UpdateAdmin(address indexed newAdmin);
    event UpdateFeedAddress(address indexed tokenAddr, address indexed feedAddr);

    constructor(address wethAddress) {
        admin = msg.sender;
        WETH_ADDR = wethAddress;
    }

    /// @dev Assume that the response has 18 decimals
    function getPrice(address token) external view returns (uint) {
        if(token == WETH_ADDR) return 1e18;
        if(priceFeed[token] == address(0)) revert Errors.PriceFeedUnavailable();
        return IPriceFeed(priceFeed[token]).getPrice(token);
    }
    
    // AdminOnly
    function setAdmin(address newAdmin) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        admin = newAdmin;
        emit UpdateAdmin(admin);
    }

    function setPriceFeed(address token, address _priceFeed) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        priceFeed[token] = _priceFeed;
        emit UpdateFeedAddress(token, priceFeed[token]);
    }
}