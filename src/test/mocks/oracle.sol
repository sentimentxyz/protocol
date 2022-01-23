pragma solidity ^0.8.0;

contract Oracle {
    function getPrice(address tokenAddr) pure public returns (uint price) {
        price = 1;
    }
}