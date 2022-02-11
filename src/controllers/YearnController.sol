// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "../utils/Ownable.sol";
import {IYToken} from "../interface/priceFeeds/IYToken.sol";
import {IController} from "../interface/controllers/IController.sol";

contract YearnController is IController, Ownable {
    bytes4 public constant DEPOSIT = 0xb6b55f25;
    bytes4 public constant WITHDRAW = 0x3ccfd60b;

    constructor() Ownable(msg.sender) {}

    function canCall(
        address target,
        bytes4 sig,
        bytes calldata data
        ) public view returns (bool, address[] memory, address[] memory) {
        return _parseArgs(target, sig);
    }

    function _parseArgs(
        address target,
        bytes4 sig
    ) internal view returns (bool, address[] memory tokensIn, address[] memory tokensOut)
    {
        if ( sig != DEPOSIT && sig != WITHDRAW ) {
            return (false, new address[](0), new address[](0));
        }
        
        tokensIn = new address[](1);
        tokensOut = new address[](1);
        address underlying = address(IYToken(target).token());
        if(sig == DEPOSIT) {
            tokensIn[0] = target;
            tokensOut[0] = underlying;
        } else {
            tokensIn[0] = underlying;
            tokensOut[0] = target;
        }
        return(true, tokensIn, tokensOut);
    }

}