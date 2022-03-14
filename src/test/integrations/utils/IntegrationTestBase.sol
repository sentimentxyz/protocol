// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../../utils/TestBase.sol";
import {WETHController} from "@controller/src/weth/WETHController.sol";
import {CurveCryptoSwapController} 
    from "@controller/src/curve/CurveCryptoSwapController.sol";

contract IntegrationTestBase is TestBase {
    
    // Controller Contracts
    WETHController public wEthController;
    CurveCryptoSwapController public curveController;

    // Arbitrum Contracts
    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address curveEthSwap = 0x960ea3e3C7FB317332d990873d354E18d7645590;
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    function setupWEthController() public {
        wEthController = new WETHController(WETH);
        controller.updateController(WETH, wEthController);
    }

    function setupCurveController() public {
        curveController = new CurveCryptoSwapController(controller);
        controller.updateController(curveEthSwap, curveController);
        controller.toggleSwapAllowance(USDT);
    }
}