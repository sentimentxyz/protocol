// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/Errors.sol";

abstract contract PriceFeedBase {
    address public admin;
    mapping(address => address) priceFeed;
    
    event UpdateAdmin(address indexed newAdmin);
    event UpdateFeed(address indexed tokenAddr, address indexed feedAddr);

    function getPrice(address token) external view virtual returns (uint);

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