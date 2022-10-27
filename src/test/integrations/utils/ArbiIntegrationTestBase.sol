// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestBase} from "../../utils/TestBase.sol";
import {WETHOracle} from "oracle/weth/WETHOracle.sol";
import {WETHController} from "controller/weth/WETHController.sol";
import {WSTETHOracle} from "oracle/wsteth/WSTETHOracle.sol";
import {AggregatorV3Interface} from "oracle/chainlink/AggregatorV3Interface.sol";

contract ArbiIntegrationTestBase is TestBase {

    // Controller Contracts
    WETHController wEthController;

    // Oracle Contracts
    WETHOracle wethOracle;
    WSTETHOracle wstethOracle;

    // Arbitrum Contracts
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;

    function setupWethController() internal {
        wEthController = new WETHController(WETH);
        controller.updateController(WETH, wEthController);
        controller.toggleTokenAllowance(WETH);

        wethOracle = new WETHOracle();
        oracle.setOracle(WETH, wethOracle);

        accountManager.toggleCollateralStatus(WETH);
    }

    function setupWSTETHOracle() internal {
        wstethOracle = new WSTETHOracle(
            AggregatorV3Interface(0xB1552C5e96B312d0Bf8b554186F846C40614a540),
            AggregatorV3Interface(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8),
            AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612)
        );
        oracle.setOracle(WSTETH, wstethOracle);
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