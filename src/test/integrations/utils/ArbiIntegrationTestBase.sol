// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {TestBase} from "../../utils/TestBase.sol";
import {WETHOracle} from "oracle/weth/WETHOracle.sol";
import {WETHController} from "controller/weth/WETHController.sol";

contract ArbiIntegrationTestBase is TestBase {

    // Controller Contracts
    WETHController wEthController;

    // Oracle Contracts
    WETHOracle wethOracle;

    // Arbitrum Contracts
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    function setupWethController() internal {
        wEthController = new WETHController(WETH);
        controller.updateController(WETH, wEthController);
        controller.toggleTokenAllowance(WETH);

        wethOracle = new WETHOracle();
        oracle.setOracle(WETH, wethOracle);
    }

    function setupOracles() internal {
        cheats.clearMockedCalls();
    }

    function wrapEth(address account, uint amt, address owner) internal {
        bytes memory data = abi.encodeWithSignature("deposit()");

        cheats.prank(owner);
        accountManager.exec(account, WETH, amt, data);
    }
}