// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/Errors.sol";

abstract contract PriceFeedBase {
    address public admin;
    mapping(address => address) priceFeed;
    
    event UpdateAdmin(address indexed newAdmin);
    event UpdateFeed(address indexed tokenAddr, address indexed feedAddr);

    function getPrice(address token) external view virtual returns (uint);

    modifier adminOnly() {
        if(msg.sender != admin) revert Errors.AdminOnly();
        _;
    }

     // AdminOnly
    function setAdmin(address newAdmin) external adminOnly {
        admin = newAdmin;
        emit UpdateAdmin(admin);
    }

    function setProxy(address token, address _priceFeed) external adminOnly {
        priceFeed[token] = _priceFeed;
        emit UpdateFeed(token, priceFeed[token]);
    }
}