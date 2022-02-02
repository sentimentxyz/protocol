// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@ds-test/src/test.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "./Cheatcode.sol";
import "./mocks/FeedAggregator.sol";

import "../LERC20.sol";
import "../LEther.sol";
import "../DefaultRateModel.sol";
import "../interface/IERC20.sol";
import "../AccountManager.sol";
import "../RiskEngine.sol";
import "../UserRegistry.sol";
import "../AccountFactory.sol";
import "../Account.sol";

import "../proxy/BeaconProxy.sol";
import "../proxy/Beacon.sol";

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
    BeaconProxy public beaconProxy;

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
        factory = new AccountFactory(address(beacon), address(beaconProxy));
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
        beaconProxy = new BeaconProxy();
    }

    function basicSetup() public {
        setUpRateModel();
        setUpAccountManager();
        setUpLEther();
        setUpLtoken();
    }
}