// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "../utils/Ownable.sol";
import {IController} from "../interface/controllers/IController.sol";

contract AaveV2Controller is Ownable, IController {
    bytes4 public constant DEPOSIT = 0xe8eda9df;
    bytes4 public constant WITHDRAW = 0x69328dec;
    mapping(address => address) public aTokenAddrFor; // TODO Query from Aave contracts instead

    constructor() Ownable(msg.sender) {}

    function canCall(
        address target,
        bytes4 sig,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory)  
    {
        return _parseArgs(sig, data);
    }

    function _parseArgs(
        bytes4 sig,
        bytes calldata data
    ) internal view returns (bool, address[] memory, address[] memory)
    {

        address aToken;
        address underlying;
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);

        underlying = abi.decode(data, (address));
        aToken = aTokenAddrFor[underlying];

        if(sig == DEPOSIT) {
            tokensIn[0] = aToken;
            tokensOut[0] = underlying;
        } else if(sig == WITHDRAW) {
            tokensIn[0] = underlying;
            tokensOut[0] = aToken;
        } else revert("AaveV2Controller: Restricted");

        return(true, tokensIn, tokensOut);
    }
}