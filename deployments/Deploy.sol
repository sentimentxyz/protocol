// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import {Proxy} from "../src/proxy/Proxy.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {Beacon} from "../src/proxy/Beacon.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Account} from "../src/core/Account.sol";
import {LEther} from "../src/tokens/LEther.sol";
import {LToken} from "../src/tokens/LToken.sol";
import {IOracle} from "oracle/core/IOracle.sol";
import {Registry} from "../src/core/Registry.sol";
import {RiskEngine} from "../src/core/RiskEngine.sol";
import {WETHOracle} from "oracle/weth/WETHOracle.sol";
import {OracleFacade} from "oracle/core/OracleFacade.sol";
import {AccountManager} from "../src/core/AccountManager.sol";
import {AccountFactory} from "../src/core/AccountFactory.sol";
import {DefaultRateModel} from "../src/core/DefaultRateModel.sol";
import {ArbiChainlinkOracle} from "oracle/chainlink/ArbiChainlinkOracle.sol";
import {ControllerFacade} from "controller/core/ControllerFacade.sol";
import {IController} from "controller/core/IController.sol";
import {AggregatorV3Interface} from "oracle/chainlink/AggregatorV3Interface.sol";
import {UniV3Controller} from "controller/uniswap/UniV3Controller.sol";
import {UniV2Controller} from "controller/uniswap/UniV2Controller.sol";
import {IUniV2Factory} from "controller/uniswap/IUniV2Factory.sol";
import {WETHController} from "controller/weth/WETHController.sol";
import {AaveV3Controller} from "controller/aave/AaveV3Controller.sol";
import {AaveEthController} from "controller/aave/AaveEthController.sol";
import {CurveCryptoSwapController} from "controller/curve/CurveCryptoSwapController.sol";
import {StableSwap2PoolController} from "controller/curve/StableSwap2PoolController.sol";
import {ATokenOracle} from "oracle/aave/ATokenOracle.sol";
import {Stable2CurveOracle} from "oracle/curve/Stable2CurveOracle.sol";
import {CurveTriCryptoOracle} from "oracle/curve/CurveTriCryptoOracle.sol";
import {UniV2LpOracle} from "oracle/uniswap/UniV2LPOracle.sol";

contract Deploy is Test {
    // Kovan
    address constant TREASURY = 0x92f473Ef0Cd07080824F5e6B0859ac49b3AEb215;

    // arbi erc20
    address constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    // chainlink price feed
    address constant SEQUENCER = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address constant ETHUSD = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address constant DAIUSD = 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a;
    address constant WBTCUSD = 0x6ce185860a4963106506C203335A2910413708e9;
    address constant USDCUSD = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address constant USDTUSD = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;

    // Aave
    address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant WETH_GATEWAY = 0xC09e69E79106861dF5d289dA88349f10e2dc6b5C;
    address constant aWETH = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;
    address constant aWBTC = 0x078f358208685046a11C85e8ad32895DED33A249;
    address constant aDAI = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

    // SushiSwap
    address constant FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address constant SLP = 0x692a0B300366D1042679397e40f3d2cb4b8F7D30;

    // Uniswap
    address constant ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    // Curve
    address constant TWOPOOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address constant TRIPOOL = 0x960ea3e3C7FB317332d990873d354E18d7645590;
    address constant TRICRYPTO = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;

    // Protocol
    Registry registryImpl;
    Registry registry = Registry(0x0326e647408D4705373F66E5c59C65Cfd1fDF9d7);
    Account account;
    AccountManager accountManagerImpl;
    AccountManager accountManager;
    RiskEngine riskEngine;
    Beacon beacon;
    AccountFactory accountFactory;
    DefaultRateModel rateModel;

    // LTokens
    LEther lEthImpl;
    LEther lEth;
    LToken lToken;
    LToken lDai;
    LToken LWBTC;

    // Controllers
    ControllerFacade controller;
    UniV3Controller uniSwapController;
    UniV2Controller sushiSwapController;
    AaveEthController aaveEthController;
    AaveV3Controller aaveController;
    CurveCryptoSwapController curveTriCryptoController;
    StableSwap2PoolController curveStableSwapController;
    WETHController wethController;

    // Oracles
    OracleFacade oracle;
    WETHOracle wethOracle;
    ArbiChainlinkOracle chainlinkOracle;
    ATokenOracle aTokenOracle;
    CurveTriCryptoOracle curveTriCryptoOracle;
    Stable2CurveOracle stable2crvOracle;
    UniV2LpOracle SLPOracle;

    function run() public {
        vm.startBroadcast();

        // Deploy protocol
        deployRegistry();
        deployAccount();
        deployBeacon();
        deployAccountManager();
        deployRiskEngine();
        deployAccountFactory();
        deployRateModel();
        enableCollateral();
        printProtocol();

        // Deploy Controllers
        deployControllerFacade();
        deployControllers();
        printControllers();

        // Deploy Oracles
        deployOracleFacade();
        deployOracles();
        printOracles();

        // // Deploy LTokens
        deployLEther();
        deployLDAI();
        deployLWBTC();
        printLTokens();

        vm.stopBroadcast();
    }

    function deployRegistry() internal {
        registryImpl = new Registry();
        registry = Registry(address(new Proxy(address(registryImpl))));
        registry.init();
    }

    function deployAccount() internal {
        account = new Account();
        registry.setAddress("ACCOUNT", address(account));
    }

    function deployBeacon() internal {
        beacon = new Beacon(address(account));
        registry.setAddress("ACCOUNT_BEACON", address(beacon));
    }

    function deployAccountManager() internal {
        accountManagerImpl = new AccountManager();
        accountManager = AccountManager(payable(address(new Proxy(address(accountManagerImpl)))));
        registry.setAddress("ACCOUNT_MANAGER", address(accountManager));
        accountManager.init(registry);
    }

    function deployRiskEngine() internal {
        riskEngine = new RiskEngine(registry);
        registry.setAddress("RISK_ENGINE", address(riskEngine));
    }

    function deployAccountFactory() internal {
        accountFactory = new AccountFactory(address(beacon));
        registry.setAddress("ACCOUNT_FACTORY", address(accountFactory));
    }

    function deployRateModel() internal {
        rateModel = new DefaultRateModel(1e17, 3e17, 35e17, 31556952e18);
        registry.setAddress("RATE_MODEL", address(rateModel));
    }

    function deployOracleFacade() internal {
        oracle = new OracleFacade();
        registry.setAddress("ORACLE", address(oracle));
    }

    function deployControllerFacade() internal {
        controller = new ControllerFacade();
        registry.setAddress("CONTROLLER", address(controller));
    }

    function initDependencies() internal {
        accountManager.initDep();
        riskEngine.initDep();
    }

    function deployLEther() internal {
        lEthImpl = new LEther();
        lEth = LEther(payable(address(new Proxy(address(lEthImpl)))));
        lEth.init(ERC20(WETH9), "LEther", "LETH", registry, 1e17, TREASURY);
        registry.setLToken(WETH9, address(lEth));
        lEth.initDep("RATE_MODEL");
    }

    function deployLDAI() internal {
        lToken = new LToken();
        lDai = LToken(address(new Proxy(address(lToken))));
        lDai.init(ERC20(DAI), "LDai", "LDAI", registry, 1e17, TREASURY);
        registry.setLToken(DAI, address(lDai));
        lDai.initDep("RATE_MODEL");
    }

    function deployLWBTC() internal {
        LWBTC = LToken(address(new Proxy(address(lToken))));
        LWBTC.init(ERC20(WBTC), "LWrapped Bitcoin", "LWBTC", registry, 1e17, TREASURY);
        registry.setLToken(WBTC, address(LWBTC));
        lDai.initDep("RATE_MODEL");
    }

    function deployWETHOracle() internal {
        wethOracle = new WETHOracle();
        oracle.setOracle(address(0), IOracle(wethOracle));
        oracle.setOracle(WETH9, IOracle(wethOracle));
    }

    function deployChainlinkOracle() internal {
        chainlinkOracle = new ArbiChainlinkOracle(
            AggregatorV3Interface(SEQUENCER), AggregatorV3Interface(ETHUSD)
        );
        configureChainLinkOracle(DAI, DAIUSD);
        configureChainLinkOracle(WBTC, WBTCUSD);
        configureChainLinkOracle(USDC, USDCUSD);
        configureChainLinkOracle(USDT, USDTUSD);
    }

    function configureChainLinkOracle(address token, address feed) internal {
        chainlinkOracle.setFeed(token, AggregatorV3Interface(feed));
        oracle.setOracle(token, chainlinkOracle);
    }

    function enableCollateral() internal {
        accountManager.toggleCollateralStatus(WETH9);
        accountManager.toggleCollateralStatus(DAI);
        accountManager.toggleCollateralStatus(USDC);
        accountManager.toggleCollateralStatus(USDT);
        accountManager.toggleCollateralStatus(WBTC);
    }

    function deployControllers() internal {
        // aave
        aaveEthController = new AaveEthController(aWETH);
        aaveController = new AaveV3Controller(controller);
        controller.updateController(AAVE_POOL, aaveController);
        controller.updateController(WETH_GATEWAY, aaveEthController);
        controller.toggleTokenAllowance(aWETH);
        controller.toggleTokenAllowance(aWBTC);
        controller.toggleTokenAllowance(aDAI);

        // uniswap
        uniSwapController = new UniV3Controller(controller);
        controller.updateController(ROUTER, uniSwapController);
        controller.toggleTokenAllowance(WETH9);
        controller.toggleTokenAllowance(WBTC);
        controller.toggleTokenAllowance(DAI);

        // sushi swap
        sushiSwapController = new UniV2Controller(WETH9, IUniV2Factory(FACTORY), controller);
        controller.toggleTokenAllowance(SLP);
        controller.updateController(SUSHI_ROUTER, sushiSwapController);

        // WETH
        wethController = new WETHController(WETH9);
        controller.updateController(WETH9, wethController);

        // curve
        curveStableSwapController = new StableSwap2PoolController();
        controller.updateController(TWOPOOL, curveStableSwapController);
        curveTriCryptoController = new CurveCryptoSwapController();
        controller.updateController(TRIPOOL, curveTriCryptoController);
    }

    function deployOracles() internal {
        deployWETHOracle();
        deployChainlinkOracle();

        // Aave
        aTokenOracle = new ATokenOracle(oracle);
        oracle.setOracle(aWETH, aTokenOracle);
        oracle.setOracle(aDAI, aTokenOracle);
        oracle.setOracle(aWBTC, aTokenOracle);

        // Sushi
        SLPOracle = new UniV2LpOracle(oracle);
        oracle.setOracle(SLP, SLPOracle);

        // curveTriCryptoOracle = new CurveTriCryptoOracle();
        // oracle.setOracle(TRICYRPTO, curveTriCryptoOracle);

        stable2crvOracle = new Stable2CurveOracle(oracle);
        oracle.setOracle(TWOPOOL, stable2crvOracle);
    }

    function printProtocol() internal view {
        console.log("Registry Impl", address(registryImpl));
        console.log("Registry", address(registry));
        console.log("Account", address(account));
        console.log("Account Manager Impl", address(accountManagerImpl));
        console.log("Account Manager", address(accountManager));
        console.log("Risk Engine", address(riskEngine));
        console.log("Beacon", address(beacon));
        console.log("Account Factory", address(accountFactory));
        console.log("Rate Model", address(rateModel));
    }

    function printOracles() internal view {
        console.log("Oracle Facade", address(oracle));
        console.log("WETH Oracle", address(wethOracle));
        console.log("ChainlinkOracle", address(chainlinkOracle));
        console.log("AToken Oracle", address(aTokenOracle));
        console.log("SLP Oracle", address(SLPOracle));
        console.log("stable2crvOracle", address(stable2crvOracle));
    }

    function printLTokens() internal view {
        console.log("LEther Impl", address(lEthImpl));
        console.log("LEther", address(lEth));
        console.log("LToken", address(lToken));
        console.log("LDai", address(lDai));
        console.log("LWBTC", address(LWBTC));
    }

    function printControllers() internal view {
        console.log("Controller Facade", address(controller));
        console.log("Uniswap Controller", address(uniSwapController));
        console.log("Sushi swap Controller", address(sushiSwapController));
        console.log("Aave Controller", address(aaveController));
        console.log("Aave Eth Controller", address(aaveEthController));
        console.log("WETH Controller", address(wethController));
        console.log("Curve Stable Swap Controller", address(curveStableSwapController));
        console.log("Curve Crypto Swap Controller", address(curveTriCryptoController));
    }
}