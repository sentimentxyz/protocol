// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IController} from "../interface/controllers/IController.sol";
import {IStableSwapPool} from "../interface/controllers/IStableSwapPool.sol";

contract CurveController is IController {
    bytes4 public constant EXCHANGE = 0x3df02124;

    function canCall(
        address target,
        bytes4 sig,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory)  
    {
        if(sig != EXCHANGE) return (false, new address[](0), new address[](0));
        return _parseArgs(target, data);
    }

    function _parseArgs(
        address target, 
        bytes calldata data
    ) internal view returns (bool, address[] memory, address[] memory) {
        (int128 i, int128 j) = abi.decode(data, (int128, int128));
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);

        tokensOut[0] = IStableSwapPool(target).coins(uint128(i));
        tokensIn[0] = IStableSwapPool(target).coins(uint128(j));
        return (true, tokensIn, tokensOut);
    }
}