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
import {ChainlinkOracle} from "oracle/chainlink/ChainlinkOracle.sol";
import {ControllerFacade} from "controller/core/ControllerFacade.sol";
import {AggregatorV3Interface} from "oracle/chainlink/AggregatorV3Interface.sol";

contract Deploy is Test {
    // Kovan
    address constant TREASURY = 0xc6E058a257eD5EFD6F14DB90dF58754d6963d542;
    address constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address constant DAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address constant ETHUSD = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address constant DAIUSD = 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a;

    Registry registryImpl;
    Registry registry;
    Account account;
    AccountManager accountManagerImpl;
    AccountManager accountManager;
    RiskEngine riskEngine;
    Beacon beacon;
    AccountFactory accountFactory;
    DefaultRateModel rateModel;
    OracleFacade oracle;
    ControllerFacade controller;
    LEther lEthImpl;
    LEther lEth;
    LToken lToken;
    LToken lDai;
    WETHOracle wethOracle;
    ChainlinkOracle chainlinkOracle;


    function run() public {
        vm.startBroadcast();

        // Registry
        registryImpl = new Registry();
        registry = Registry(address(new Proxy(address(registryImpl))));
        registry.init();

        // Account
        account = new Account();
        registry.setAddress("ACCOUNT", address(account));

        // Account Manager
        accountManagerImpl = new AccountManager();
        accountManager = AccountManager(payable(address(new Proxy(address(accountManagerImpl)))));
        registry.setAddress("ACCOUNT_MANAGER", address(accountManager));
        accountManager.init(registry);

        // Risk Engine
        riskEngine = new RiskEngine(registry);
        registry.setAddress("RISK_ENGINE", address(riskEngine));

        // Beacon
        beacon = new Beacon(address(account));
        registry.setAddress("ACCOUNT_BEACON", address(beacon));

        // Account Factory
        accountFactory = new AccountFactory(address(beacon));
        registry.setAddress("ACCOUNT_FACTORY", address(accountFactory));

        // Rate Model
        rateModel = new DefaultRateModel(1e17, 3e17, 35e17, 2102400e18);
        registry.setAddress("RATE_MODEL", address(rateModel));

        // Oracle Facade
        oracle = new OracleFacade();
        registry.setAddress("ORACLE", address(oracle));

        // Controller Facade
        controller = new ControllerFacade();
        registry.setAddress("CONTROLLER", address(controller));
        controller.toggleTokenAllowance(WETH9);
        controller.toggleTokenAllowance(DAI);

        // initDep
        accountManager.initDep();
        riskEngine.initDep();

        // LETH
        lEthImpl = new LEther();
        lEth = LEther(payable(address(new Proxy(address(lEthImpl)))));
        lEth.init(ERC20(WETH9), "LEther", "LETH", registry, 1e17, TREASURY);
        registry.setLToken(WETH9, address(lEth));
        accountManager.toggleCollateralStatus(WETH9);
        lEth.initDep("RATE_MODEL");

        // LDAI
        lToken = new LToken();
        lDai = LToken(address(new Proxy(address(lToken))));
        lDai.init(ERC20(DAI), "LDai", "LDAI", registry, 1e17, TREASURY);
        registry.setLToken(DAI, address(lDai));
        accountManager.toggleCollateralStatus(DAI);
        lDai.initDep("RATE_MODEL");

        // WETH Oracle
        wethOracle = new WETHOracle();
        oracle.setOracle(address(0), IOracle(wethOracle));
        oracle.setOracle(WETH9, IOracle(wethOracle));

        // Chainlink Oracle
        chainlinkOracle = new ChainlinkOracle(AggregatorV3Interface(ETHUSD));
        chainlinkOracle.setFeed(DAI, AggregatorV3Interface(DAIUSD));
        oracle.setOracle(DAI, chainlinkOracle);

        // Log Contract Addresses
        console.log("Registry Impl", address(registryImpl));
        console.log("Registry", address(registry));
        console.log("Account", address(account));
        console.log("Account Manager Impl", address(accountManagerImpl));
        console.log("Account Manager", address(accountManager));
        console.log("Risk Engine", address(riskEngine));
        console.log("Beacon", address(beacon));
        console.log("Account Factory", address(accountFactory));
        console.log("Rate Model", address(rateModel));
        console.log("Oracle Facade", address(oracle));
        console.log("Controller Facade", address(controller));
        console.log("LEther Impl", address(lEthImpl));
        console.log("LEther", address(lEth));
        console.log("LToken", address(lToken));
        console.log("LDai", address(lDai));
        console.log("WETH Oracle", address(wethOracle));
        console.log("ChainlinkOracle", address(chainlinkOracle));

        vm.stopBroadcast();
    }
}