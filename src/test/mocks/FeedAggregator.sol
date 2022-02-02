// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract FeedAggregator {
    function getPrice(address tokenAddr) pure public returns (uint price) {
        price = 1 ether;
    }
}