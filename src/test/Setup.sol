// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@ds-test/src/test.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "../utils/ContractNames.sol";

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
import "../AddressProvider.sol";

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

    AddressProvider public addressProvider;

    function setUpLEther() public {
        lEther = new LEther("LEther", "LETH", 1, address(0), address(addressProvider), 1);
        addressProvider.setLToken(address(0), address(lEther));
        accountManager.toggleCollateralState(address(0));
    }

    function setUpLtoken() public {
        token = new ERC20PresetMinterPauser("Sentiment", "STM");
        ltoken = new LERC20("LSentiment", "LSTM", 1, address(token), address(addressProvider), 1);
        addressProvider.setLToken(address(token), address(ltoken));
        accountManager.toggleCollateralState(address(token));
    }

    function setUpAccountManager() public {
        setUpBeaconProxy();
        riskEngine = setUpRiskEngine();
        setUpAccountFactory();
        setUpUserRegistry();
        accountManager = new AccountManager(address(addressProvider));
        addressProvider.setAddress(ContractNames.AccountManager, address(accountManager));
    }

    function setUpUserRegistry() public {
        userRegistry = new UserRegistry(address(addressProvider));
        addressProvider.setAddress(ContractNames.UserRegistry, address(userRegistry));
    }

    function setUpAccountFactory() public {
        factory = new AccountFactory(address(addressProvider));
        addressProvider.setAddress(ContractNames.AccountFactory, address(factory));
    }

    function setUpRiskEngine() public returns (RiskEngine engine) {
        FeedAggregator priceFeed = new FeedAggregator();
        addressProvider.setAddress(ContractNames.FeedAggregator, address(priceFeed));
        engine = new RiskEngine(address(addressProvider));
        addressProvider.setAddress(ContractNames.RiskEngine, address(engine));
    }

    function setUpRateModel() public {
        rateModel = new DefaultRateModel();
        addressProvider.setAddress(ContractNames.DefaultRateModel, address(rateModel));
    }
    
    function setUpBeaconProxy() public {
        marginAccount = new Account();
        beacon = new Beacon(address(marginAccount));
        addressProvider.setAddress(ContractNames.AccountBeacon, address(beacon));
    }

    function setUpAddressProvider() public {
        addressProvider = new AddressProvider();
    }

    function basicSetup() public {
        setUpAddressProvider();
        setUpRateModel();
        setUpAccountManager();
        setUpLEther();
        setUpLtoken();
    }
}