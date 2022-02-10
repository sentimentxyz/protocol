// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IController} from "../interface/controllers/IController.sol";

contract WETHController is IController {
    bytes4 constant DEPOSIT_SIG = 0xd0e30db0;
    bytes4 constant WITHDRAW_SIG = 0x2e1a7d4d;
    address constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function canCall(
        address target,
        bytes4 sig,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory)
    {   
        if(sig == DEPOSIT_SIG || sig == WITHDRAW_SIG) {
            // the outputs are known, the sig only affects their order
            // so initialize the arrays beforehand and return as per sig
            address[] memory wethArr = new address[](1);
            wethArr[0] = WETH_ADDR;

            if(sig == DEPOSIT_SIG) return (true, wethArr, new address[](0));
            else return (true, new address[](0), wethArr);
        }
        return (false, new address[](0), new address[](0));
        // TODO do we need any checks on data?
    }
}