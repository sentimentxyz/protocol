// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/Errors.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkFeed {
    address public admin;
    mapping(address => address) priceFeed;

    event UpdateAdmin(address indexed newAdmin);
    event UpdateFeed(address indexed token, address indexed proxy);

    constructor() {
        admin = msg.sender;
    }

    /// @dev Assume that the response has 18 decimals
    function getPrice(address token) external view returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(priceFeed[token]).latestRoundData();
        return uint(price);
    }

     // AdminOnly
    function setAdmin(address newAdmin) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        admin = newAdmin;
        emit UpdateAdmin(admin);
    }

    function setProxy(address token, address _priceFeed) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        priceFeed[token] = _priceFeed;
        emit UpdateFeed(token, priceFeed[token]);
    }
}