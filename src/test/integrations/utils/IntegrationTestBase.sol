// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../../utils/TestBase.sol";
import {WETHOracle} from "oracle/weth/WETHOracle.sol";
import {WETHController} from "controller/weth/WETHController.sol";
import {ChainlinkOracle} from "oracle/chainlink/ChainlinkOracle.sol";
import {CurveTriCryptoOracle} from "oracle/curve/CurveTriCryptoOracle.sol";
import {AggregatorV3Interface}
    from "oracle/chainlink/AggregatorV3Interface.sol";
import {CurveCryptoSwapController}
    from "controller/curve/CurveCryptoSwapController.sol";

contract IntegrationTestBase is TestBase {

    // Controller Contracts
    WETHController wEthController;
    CurveCryptoSwapController curveController;

    // Oracle Contracts
    WETHOracle wethOracle;
    CurveTriCryptoOracle curveOracle;
    ChainlinkOracle chainlinkOracle;

    // Ethereum Contracts
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant tricryptoPool = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address constant crv3crypto = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;

    // Chainlink contracts
    address constant ETHUSD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant USDTUSD = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address constant DAIUSD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

    function setupWethController() internal {
        wEthController = new WETHController(WETH);
        controller.updateController(WETH, wEthController);
        controller.toggleTokenAllowance(WETH);

        wethOracle = new WETHOracle();
        oracle.setOracle(WETH, wethOracle);
    }

    function setupCurveController() internal {
        curveController = new CurveCryptoSwapController(controller);
        controller.updateController(tricryptoPool, curveController);
        controller.toggleTokenAllowance(USDT);

        curveOracle = new CurveTriCryptoOracle(tricryptoPool);
        oracle.setOracle(crv3crypto, curveOracle);
    }

    function setupChainLinkOracles() internal {
        chainlinkOracle = new ChainlinkOracle(AggregatorV3Interface(ETHUSD));
        oracle.setOracle(USDT, chainlinkOracle);
        oracle.setOracle(DAI, chainlinkOracle);
        chainlinkOracle.setFeed(USDT, AggregatorV3Interface(USDTUSD));
        chainlinkOracle.setFeed(DAI, AggregatorV3Interface(DAIUSD));
    }

    function setupOracles() internal {
        cheats.clearMockedCalls();
        setupChainLinkOracles();
    }

    function swapEthUsdt(uint amt, address account, address owner) internal {
        // Encode Calldata
        bytes memory data = abi.encodeWithSignature(
            "exchange(uint256,uint256,uint256,uint256,bool)",
            uint256(2), // WETH
            uint256(0), // USDT
            amt,
            0,
            true
        );

        // Swap
        cheats.prank(owner);
        accountManager.exec(account, tricryptoPool, amt, data);
    }

    function wrapEth(address account, uint amt, address owner) internal {
        bytes memory data = abi.encodeWithSignature("deposit()");

        cheats.prank(owner);
        accountManager.exec(account, WETH, amt, data);
    }

    function depositCurveLiquidity(address account, uint amt, address owner)
        internal
    {
        cheats.prank(owner);
        accountManager.exec(
            account,
            WETH,
            amt,
            abi.encodeWithSignature("deposit()")
        );

        // Encode Calldata
        bytes memory data = abi.encodeWithSignature(
            "add_liquidity(uint256[3],uint256)",
            [0, 0, amt],
            0
        );

        // Test
        cheats.startPrank(owner);
        accountManager.approve(account, WETH, tricryptoPool, amt);
        accountManager.exec(account, tricryptoPool, 0, data);
        cheats.stopPrank();
    }
}