// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestERC20} from "./TestERC20.sol";
import {CheatCodes} from "./CheatCodes.sol";
import {DSTest} from "ds-test/test.sol";
import {Beacon} from "../../proxy/Beacon.sol";
import {Account} from "../../core/Account.sol";
import {LERC20} from "../../tokens/LERC20.sol";
import {LEther} from "../../tokens/LEther.sol";
import {Registry} from "../../core/Registry.sol";
import {RiskEngine} from "../../core/RiskEngine.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {AccountFactory} from "../../core/AccountFactory.sol";
import {OracleFacade} from "oracle/core/OracleFacade.sol";
import {DefaultRateModel} from "../../core/DefaultRateModel.sol";
import {ControllerFacade} from "controller/core/ControllerFacade.sol";

abstract contract TestBase is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    uint constant MAX_LEVERAGE = 5;

    // Dummy ERC20 Token
    TestERC20 erc20;

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
        erc20 = new TestERC20("TestERC20", "TEST", uint8(18));

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

        lEth = new LEther(address(registry), uint(1));
        lErc20 = new LERC20(
            "LERC20Test",
            "LERC20",
            uint8(18),
            address(erc20),
            address(registry),
            uint(1)
        );
    }

    function register() private {
        registry.setAddress('ORACLE', address(oracle));
        registry.setAddress('CONTROLLER', address(controller));
        registry.setAddress('RATE_MODEL', address(rateModel));
        registry.setAddress('RISK_ENGINE', address(riskEngine));
        registry.setAddress('ACCOUNT_FACTORY', address(accountFactory));
        registry.setAddress('ACCOUNT_MANAGER', address(accountManager));

        registry.setLToken(address(0), address(lEth));
        registry.setLToken(address(erc20), address(lErc20));
    }

    function initialize() private {
        riskEngine.initialize();
        accountManager.initialize();
        lEth.initialize('RATE_MODEL');
        lErc20.initialize('RATE_MODEL');

        accountManager.toggleCollateralStatus(address(erc20));
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

    function isContract(address _contract) internal view returns (bool size) {
        assembly { size := gt(extcodesize(_contract), 0x0) }
    }
}
