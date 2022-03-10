// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {CheatCodes} from "./CheatCodes.sol";
import {DSTest} from "@ds-test/src/test.sol";
import {Beacon} from "../../proxy/Beacon.sol";
import {Account} from "../../core/Account.sol";
import {LERC20} from "../../tokens/LERC20.sol";
import {LEther} from "../../tokens/LEther.sol";
import {RiskEngine} from "../../core/RiskEngine.sol";
import {UserRegistry} from "../../core/UserRegistry.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {AccountFactory} from "../../core/AccountFactory.sol";
import {IOracle} from "../../interface/periphery/IOracle.sol";
import {DefaultRateModel} from "../../core/DefaultRateModel.sol";
import {WETHController} from "@controller/src/weth/WETHController.sol";
import {ControllerFacade} from "@controller/src/core/ControllerFacade.sol";
import {ERC20PresetMinterPauser} from
    "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

abstract contract TestBase is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    uint public constant MAX_LEVERAGE = 5;

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

    // Controller Contracts
    ControllerFacade public controller;
    WETHController public wEthController;

    // Arbitrum Contracts
    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // Contract Setup Functions
    function setupContracts() public virtual {
        setupRateModel();
        setupOracle();
        setupRiskEngine();
        setupBeacon();
        setupAccountFactory();
        setupUserRegistry();
        setupController();
        setupAccountManager();
        setupLEther();
        setupLERC20();
    }

    function setupRateModel() private {
        rateModel = new DefaultRateModel();
    }

    function setupOracle() private {
        // Assume oracle is deployed at address(0)
        cheats.mockCall(
            address(0),
            abi.encodeWithSelector(IOracle.getPrice.selector),
            abi.encode(1e18)
        );
    }

    function setupRiskEngine() private {
        riskEngine = new RiskEngine(address(0));
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
            address(userRegistry),
            address(controller)
        );
        riskEngine.setAccountManagerAddress(address(accountManager));
        userRegistry.setAccountManagerAddress(address(accountManager));
    }

    function setupLEther() private {
        lEth = new LEther(address(rateModel), address(accountManager), 1);
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
        accountManager.toggleCollateralState(address(erc20));
    }

    function setupController() public {
        controller = new ControllerFacade();
    }

    function setupWEthController() public {
        wEthController = new WETHController(WETH);
        controller.updateController(WETH, wEthController);
    }

    // Test Helper Functions
    function openAccount(address owner) public returns (address account) {
        accountManager.openAccount(owner);
        account = userRegistry.accountsOwnedBy(owner)[0];
    }

    function deposit(
        address owner,
        address account,
        address token,
        uint amt
    )
        public
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
        public
    {
        if (token == address(0)) {
            cheats.deal(address(lEth), amt);
            cheats.prank(owner);
            accountManager.borrow(account, token, amt);
        } else {
            erc20.mint(accountManager.LTokenAddressFor(token), amt);
            cheats.prank(owner);
            accountManager.borrow(account, token, amt);
        }
    }

    function assertFalse(bool condition) public {
        if (condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }
}
