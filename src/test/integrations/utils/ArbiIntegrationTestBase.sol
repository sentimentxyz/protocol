// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestBase} from "../../utils/TestBase.sol";
import {WETHOracle} from "oracle/weth/WETHOracle.sol";
import {WETHController} from "controller/weth/WETHController.sol";
import {WSTETHOracle} from "oracle/wsteth/WSTETHOracle.sol";
import {AggregatorV3Interface} from "oracle/chainlink/AggregatorV3Interface.sol";
import {ChainlinkOracle} from "oracle/chainlink/ChainlinkOracle.sol";

contract ArbiIntegrationTestBase is TestBase {

    // Controller Contracts
    WETHController wEthController;

    // Oracle Contracts
    WETHOracle wethOracle;
    WSTETHOracle wstethOracle;
    ChainlinkOracle chainlinkOracle;

    // Arbitrum Contracts
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant BAL = 0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8;

    address constant BALUSD = 0xBE5eA816870D11239c543F84b71439511D70B94f;
    address constant ETHUSD = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address constant USDCUSD = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address constant USDTUSD = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;
    address constant WBTCUSD = 0x6ce185860a4963106506C203335A2910413708e9;

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
            AggregatorV3Interface(0x07C5b924399cc23c24a95c8743DE4006a32b7f2a),
            AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612)
        );
        oracle.setOracle(WSTETH, wstethOracle);
        controller.toggleTokenAllowance(WSTETH);
    }

    function setupOracles() internal {
        cheats.clearMockedCalls();
    }

    function wrapEth(address account, uint amt, address owner) internal {
        bytes memory data = abi.encodeWithSignature("deposit()");

        cheats.prank(owner);
        accountManager.exec(account, WETH, amt, data);
    }

    function setupChainLinkOracles() internal {
        chainlinkOracle = new ChainlinkOracle(AggregatorV3Interface(ETHUSD));
        oracle.setOracle(USDT, chainlinkOracle);
        oracle.setOracle(USDC, chainlinkOracle);
        oracle.setOracle(WBTC, chainlinkOracle);
        oracle.setOracle(BAL, chainlinkOracle);
        controller.toggleTokenAllowance(USDT);
        controller.toggleTokenAllowance(BAL);
        controller.toggleTokenAllowance(USDC);
        controller.toggleTokenAllowance(WBTC);
        chainlinkOracle.setFeed(USDT, AggregatorV3Interface(USDTUSD), 86400);
        chainlinkOracle.setFeed(USDC, AggregatorV3Interface(USDCUSD), 86400);
        chainlinkOracle.setFeed(WBTC, AggregatorV3Interface(WBTCUSD), 3600);
        chainlinkOracle.setFeed(BAL, AggregatorV3Interface(BALUSD), 3600);
    }
}