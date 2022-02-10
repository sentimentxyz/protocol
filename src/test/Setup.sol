// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DSTest} from "@ds-test/src/test.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import {CheatCode} from "./Cheatcode.sol";
import {FeedAggregator} from "./mocks/FeedAggregator.sol";

import {Account} from "../core/Account.sol";
import {LERC20} from "../core/tokens/LERC20.sol";
import {LEther} from "../core/tokens/LEther.sol";
import {RiskEngine} from "../core/RiskEngine.sol";
import {UserRegistry} from "../core/UserRegistry.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {AccountManager} from "../core/AccountManager.sol";
import {AccountFactory} from "../core/AccountFactory.sol";
import {DefaultRateModel} from "../core/DefaultRateModel.sol";

import {Beacon} from "../proxy/Beacon.sol";
import {BeaconProxy} from "../proxy/BeaconProxy.sol";

contract Test is DSTest {
    CheatCode cheatCode = CheatCode(HEVM_ADDRESS);

    LERC20 public ltoken;
    LEther public lEther;
    ERC20PresetMinterPauser public token;

    DefaultRateModel public rateModel;
    
    AccountManager public accountManager;
    RiskEngine public riskEngine;
    UserRegistry public userRegistry;
    AccountFactory public factory;
    Account public marginAccount;

    Beacon public beacon;

    function setUpLEther() public {
        lEther = new LEther("LEther", "LETH", 1, address(0), address(rateModel), address(accountManager), 1);
        accountManager.setLTokenAddress(address(0), address(lEther));
        accountManager.toggleCollateralState(address(0));
    }

    function setUpLtoken() public {
        token = new ERC20PresetMinterPauser("Sentiment", "STM");
        ltoken = new LERC20("LSentiment", "LSTM", 1, address(token), address(rateModel), address(accountManager), 1);
        accountManager.setLTokenAddress(address(token), address(ltoken));
        accountManager.toggleCollateralState(address(token));
    }

    function setUpAccountManager() public {
        setUpBeaconProxy();
        riskEngine = setUpRiskEngine();
        factory = new AccountFactory(address(beacon));
        userRegistry = new UserRegistry();
        accountManager = new AccountManager(address(riskEngine), address(factory), address(userRegistry));
        riskEngine.setAccountManagerAddr(address(accountManager));
        userRegistry.setAccountManagerAddress(address(accountManager));
    }

    function setUpRiskEngine() public returns (RiskEngine engine) {
        FeedAggregator priceFeed = new FeedAggregator();
        engine = new RiskEngine(address(priceFeed));
    }

    function setUpRateModel() public {
        rateModel = new DefaultRateModel();
    }
    
    function setUpBeaconProxy() public {
        marginAccount = new Account();
        beacon = new Beacon(address(marginAccount));
    }

    function basicSetup() public {
        setUpRateModel();
        setUpAccountManager();
        setUpLEther();
        setUpLtoken();
    }
}