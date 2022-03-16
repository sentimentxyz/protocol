// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../../utils/TestBase.sol";
import {WETHController} from "@controller/src/weth/WETHController.sol";

contract IntegrationTestBase is TestBase {
    
    // Controller Contracts
    WETHController public wEthController;

    // Arbitrum Contracts
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    function setupWethController() internal {
        wEthController = new WETHController(address(WETH));
        controller.updateController(address(WETH), wEthController);
    }
}