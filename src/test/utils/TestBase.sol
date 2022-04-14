// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test} from "forge-std/Test.sol";
import {TestERC20} from "./TestERC20.sol";
import {CheatCodes} from "./CheatCodes.sol";
import {Proxy} from "../../proxy/Proxy.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {Beacon} from "../../proxy/Beacon.sol";
import {Account} from "../../core/Account.sol";
import {LEther} from "../../tokens/LEther.sol";
import {LToken} from "../../tokens/LToken.sol";
import {ILToken} from "../../interface/tokens/ILToken.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Registry} from "../../core/Registry.sol";
import {RiskEngine} from "../../core/RiskEngine.sol";
import {OracleFacade} from "oracle/core/OracleFacade.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {AccountFactory} from "../../core/AccountFactory.sol";
import {IRegistry} from "../../interface/core/IRegistry.sol";
import {DefaultRateModel} from "../../core/DefaultRateModel.sol";
import {IAccountManager} from "../../interface/core/IAccountManager.sol";
import {ControllerFacade} from "controller/core/ControllerFacade.sol";

contract TestBase is Test {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    uint constant MAX_LEVERAGE = 5;

    // Test ERC20 Tokens
    WETH weth;
    TestERC20 erc20;

    // LTokens
    LEther lEth;
    LToken lErc20;

    // Core Contracts
    RiskEngine riskEngine;
    
    Registry registryImplementation;
    IRegistry registry;

    AccountManager accountManagerImplementation;
    IAccountManager accountManager;

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
        // Log block number
        emit log_uint(block.number);
        
        // Deploy Dummy ERC20
        erc20 = new TestERC20("TestERC20", "TEST", uint8(18));
        weth = new WETH();

        deploy();
        register();
        initialize();
        mock();
    }

    function deploy() private {
        // Registry deployment
        registryImplementation = new Registry();
        registry = IRegistry(
            address(new Proxy(address(registryImplementation)))
        );
        registry.initialize(address(this));
        
        oracle = new OracleFacade();
        rateModel = new DefaultRateModel();
        controller = new ControllerFacade();
        riskEngine = new RiskEngine(registry);
        
        // Account Manager deployment
        accountManagerImplementation = new AccountManager(registry);
        accountManager = IAccountManager(
            address(new Proxy(address(accountManagerImplementation)))
        );
        accountManager.initialize(address(this), registry);
        
        beacon = new Beacon(address(new Account()));
        accountFactory = new AccountFactory(address(beacon));

        lEth = new LEther(weth, registry, 0);
        lErc20 = new LToken(erc20, "LTestERC20", "LERC20", registry, 0);
    }

    function register() private {
        registry.setAddress('ORACLE', address(oracle));
        registry.setAddress('CONTROLLER', address(controller));
        registry.setAddress('RATE_MODEL', address(rateModel));
        registry.setAddress('RISK_ENGINE', address(riskEngine));
        registry.setAddress('ACCOUNT_FACTORY', address(accountFactory));
        registry.setAddress('ACCOUNT_MANAGER', address(accountManager));

        registry.setLToken(address(weth), address(lEth));
        registry.setLToken(address(erc20), address(lErc20));
    }

    function initialize() private {
        riskEngine.initializeDependencies();
        accountManager.initializeDependencies();
        lEth.initializeDependencies('RATE_MODEL');
        lErc20.initializeDependencies('RATE_MODEL');

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
        if (token == address(weth)) {
            cheats.deal(address(lEth), amt);
            cheats.prank(address(lEth));
            weth.deposit{value: amt}();
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
