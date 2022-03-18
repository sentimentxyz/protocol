// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {CheatCodes} from "./CheatCodes.sol";
import {DSTest} from "@ds-test/src/test.sol";
import {Beacon} from "../../proxy/Beacon.sol";
import {Account} from "../../core/Account.sol";
import {LERC20} from "../../tokens/LERC20.sol";
import {LEther} from "../../tokens/LEther.sol";
import {Registry} from "../../core/Registry.sol";
import {RiskEngine} from "../../core/RiskEngine.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {AccountFactory} from "../../core/AccountFactory.sol";
import {OracleFacade} from "@oracle/src/core/OracleFacade.sol";
import {DefaultRateModel} from "../../core/DefaultRateModel.sol";
import {ControllerFacade} from "@controller/src/core/ControllerFacade.sol";
import {ERC20PresetMinterPauser} from
    "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import {console} from "../utils/console.sol";

contract TestBase is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    uint constant MAX_LEVERAGE = 5;

    // Dummy ERC20 Token
    ERC20PresetMinterPauser erc20;

    // LTokens
    LEther lEth;
    LERC20 lErc20;

    // Core Contracts
    RiskEngine riskEngine;
    Registry registry;
    AccountManager accountManager;

    // Account Factory
    Beacon beacon;
    AccountFactory accountFactory;

    // Rate Model
    DefaultRateModel rateModel;

    // Controller
    ControllerFacade controller;

    // Oracle
    OracleFacade oracle;

    // Contract Setup Functions
    function setupContracts() internal virtual {
        // Deploy Dummy ERC20
        erc20 = new ERC20PresetMinterPauser("TestERC20", "TEST");

        deploy();
        register();
        initialize();
        mock();
    }

    function deploy() private {
        registry = new Registry();
        oracle = new OracleFacade();
        rateModel = new DefaultRateModel();
        controller = new ControllerFacade();
        riskEngine = new RiskEngine(registry);
        accountManager = new AccountManager(registry);
        
        beacon = new Beacon(address(new Account()));
        accountFactory = new AccountFactory(address(beacon));

        lEth = new LEther(uint(1), address(registry));
        lErc20 = new LERC20(
            "LERC20Test",
            "LERC20",
            uint8(18),
            address(erc20),
            uint(1),
            address(registry)
        );
    }

    function register() private {
        registry.setAddress('ORACLE', address(oracle));
        registry.setAddress('CONTROLLER', address(controller));
        registry.setAddress('RATE_MODEL', address(rateModel));
        registry.setAddress('RISK_ENGINE', address(riskEngine));
        registry.setAddress('ACCOUNT_FACTORY', address(accountFactory));
        registry.setAddress('ACCOUNT_MANAGER', address(accountManager));

        registry.addLToken(address(0), address(lEth));
        registry.addLToken(address(erc20), address(lErc20));
    }

    function initialize() private {
        riskEngine.initialize();
        accountManager.initialize();
        lEth.initialize();
        lErc20.initialize();
    }

    function mock() private {
        // Mock Oracle to return 1e18 for all calls
        cheats.mockCall(
            address(oracle),
            abi.encodeWithSelector(OracleFacade.getPrice.selector),
            abi.encode(1e18)
        );
    }

    // Test Helper Functions
    function openAccount(address owner) internal returns (address account) {
        accountManager.openAccount(owner);
        account = registry.accountsOwnedBy(owner)[0];
    }

    function deposit(
        address owner,
        address account,
        address token,
        uint amt
    )
        internal
    {
        if (token == address(0)) {
            cheats.deal(owner, amt);
            cheats.prank(owner);
            accountManager.depositEth{value: amt}(account);
        } else {
            erc20.mint(owner, amt);
            cheats.startPrank(owner);
            erc20.approve(address(accountManager), type(uint).max);
            accountManager.deposit(account, token, amt);
            cheats.stopPrank();
        }
    }

    function borrow(
        address owner,
        address account,
        address token,
        uint amt
    )
        internal
    {
        if (token == address(0)) {
            cheats.deal(address(lEth), amt);
            cheats.prank(owner);
            accountManager.borrow(account, token, amt);
        } else {
            erc20.mint(registry.LTokenFor(token), amt);
            cheats.prank(owner);
            accountManager.borrow(account, token, amt);
        }
    }

    function assertFalse(bool condition) internal {
        if (condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }
}
