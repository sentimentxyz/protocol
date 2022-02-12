// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {CheatCodes} from "./CheatCodes.sol";
import {DSTest} from "@ds-test/src/test.sol";
import {Beacon} from "../../proxy/Beacon.sol";
import {Account} from "../../core/Account.sol";
import {LERC20} from "../../core/tokens/LERC20.sol";
import {LEther} from "../../core/tokens/LEther.sol";
import {RiskEngine} from "../../core/RiskEngine.sol";
import {UserRegistry} from "../../core/UserRegistry.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {AccountFactory} from "../../core/AccountFactory.sol";
import {DefaultRateModel} from "../../core/DefaultRateModel.sol";
import {FeedAggregator} from "../../priceFeeds/FeedAggregator.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

abstract contract TestBase is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    // Dummy ERC20 Token
    ERC20PresetMinterPauser public erc20;

    // LTokens
    LEther public lEth;
    LERC20 public lErc20;

    // Core Contracts
    RiskEngine public riskEngine;
    UserRegistry public userRegistry;
    AccountManager public accountManager;

    // Account Factory
    Beacon public beacon;
    AccountFactory public accountFactory;

    // Rate Model
    DefaultRateModel public rateModel;

    // Price Feeds
    FeedAggregator public feedAggregator;

    function setupContracts() public virtual {
        setupRateModel();
        setupPriceFeeds();
        setupRiskEngine();
        setupBeacon();
        setupAccountFactory();
        setupUserRegistry();
        setupAccountManager();
        setupLEther();
        setupLERC20();
    }

    function setupRateModel() private {
        rateModel = new DefaultRateModel();
    }

    function setupPriceFeeds() private {
        feedAggregator = new FeedAggregator(address(0));
        cheats.mockCall(
            address(feedAggregator),
            abi.encodeWithSelector(FeedAggregator.getPrice.selector),
            abi.encode(1e18)
        );
    }

    function setupRiskEngine() private {
        riskEngine = new RiskEngine(address(feedAggregator));
    }

    function setupBeacon() private {
        beacon = new Beacon(address(new Account()));
    }

    function setupAccountFactory() private {
        accountFactory = new AccountFactory(address(beacon));
    }

    function setupUserRegistry() private {
        userRegistry = new UserRegistry();
    }

    function setupAccountManager() private {
        accountManager = new AccountManager(
            address(riskEngine), 
            address(accountFactory), 
            address(userRegistry)
        );
        riskEngine.setAccountManagerAddress(address(accountManager));
        userRegistry.setAccountManagerAddress(address(accountManager));
    }

    function setupLEther() private {
        lEth = new LEther(
            "LEther",
            "LETH",
            1,
            address(0),
            address(rateModel),
            address(accountManager),
            1
        );
        accountManager.setLTokenAddress(address(0), address(lEth));
    }

    function setupLERC20() private {
        erc20 = new ERC20PresetMinterPauser("TestERC20", "TEST");
        lErc20 = new LERC20(
            "LERC20Test",
            "LERC20",
            1,
            address(erc20),
            address(rateModel),
            address(accountManager),
            1
        );
        accountManager.setLTokenAddress(address(erc20), address(lErc20));
    }
}
