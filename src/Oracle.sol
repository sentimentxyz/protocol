// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Errors.sol";
import "./interface/ICToken.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Oracle {
    using PRBMathUD60x18 for uint;

    address public constant DAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address public constant CDAI = 0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD;
    address public constant CETH = 0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72;
    address public constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    address public admin;
    mapping(address => address) public priceFeedAddr;

    event UpdateFeedAddress(address indexed tokenAddr, address indexed feedAddr);
    event UpdateAdmin(address indexed newAdmin);

    constructor() {
        admin = msg.sender;
    }

    /// @dev We assume that the response has 18 decimals
    function getPrice(address token) public view returns (uint) {
        // TODO Get rid of this if-else pattern
        if(token == WETH9) return 1e18; // WETH
        if(token == CETH) return ICEther(CETH).exchangeRateStored() / 1e10; // cETH
        if(token == CDAI)
            return (ICERC20(CDAI).exchangeRateStored() / 1e10).mul(_getPrice(DAI)); // cDAI;
        
        return _getPrice(token);
    }

    /// @dev We assume that the response has 18 decimals
    function _getPrice(address token) internal view returns (uint) {
        if(priceFeedAddr[token] == address(0)) revert Errors.PriceFeedUnavailable();
        (, int price, , ,) = AggregatorV3Interface(priceFeedAddr[token]).latestRoundData();
        return uint(price);
    }

    // AdminOnly
    function setFeedAddress(address token, address priceFeed) public {
        if(msg.sender != admin) revert Errors.AdminOnly();
        priceFeedAddr[token] = priceFeed;
        emit UpdateFeedAddress(token, priceFeed);
    }

    function setAdmin(address newAdmin) public {
        if(msg.sender != admin) revert Errors.AdminOnly();
        admin = newAdmin;
        emit UpdateAdmin(newAdmin);
    }
}