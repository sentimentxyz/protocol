// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "../utils/Ownable.sol";
import {IYVToken} from "../interface/priceFeeds/IYVToken.sol";
import {IZapController} from "../interface/controllers/IZapController.sol";

contract YearnZapController is IZapController, Ownable {

    mapping(address=>bool) isValidToken;

    constructor() Ownable(msg.sender) {}
    
    function canCall(
        address sellToken,
        address buyToken
    ) external view returns (bool, address[] memory, address[] memory) {

        if (!isValidToken[buyToken]) return (false, new address[](0), new address[](0));
        
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);

        tokensIn[0] = buyToken;
        tokensOut[0] = sellToken;
        
        return (true, tokensIn, tokensOut);
    }

    function toggleToken(address _token) public adminOnly {
        isValidToken[_token] = !isValidToken[_token];
    }
}