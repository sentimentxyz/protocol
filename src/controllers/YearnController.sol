// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "../utils/Ownable.sol";
import {IYVToken} from "../interface/priceFeeds/IYVToken.sol";
import {IController} from "../interface/controllers/IController.sol";

contract YearnController is IController {
    bytes4 public constant DEPOSIT = 0xb6b55f25;
    bytes4 public constant WITHDRAW = 0x3ccfd60b;

    constructor() {}

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
        tokensIn = new address[](1);
        tokensOut = new address[](1);
        if(sig == DEPOSIT) {
            tokensIn[0] = target;
            tokensOut[0] = address(IYVToken(target).token());
        } else if (sig == WITHDRAW){
            tokensIn[0] = address(IYVToken(target).token());
            tokensOut[0] = target;
        } else return (false, new address[](0), new address[](0));
        return(true, tokensIn, tokensOut);
    }

}