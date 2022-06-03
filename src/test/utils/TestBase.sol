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
import {ILEther} from "../../interface/tokens/ILEther.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Registry} from "../../core/Registry.sol";
import {RiskEngine} from "../../core/RiskEngine.sol";
import {OracleFacade} from "oracle/core/OracleFacade.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {AccountFactory} from "../../core/AccountFactory.sol";
import {IRegistry} from "../../interface/core/IRegistry.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {DefaultRateModel} from "../../core/DefaultRateModel.sol";
import {IAccountManager} from "../../interface/core/IAccountManager.sol";
import {ControllerFacade} from "controller/core/ControllerFacade.sol";

contract TestBase is Test {
    using FixedPointMathLib for uint256;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    uint constant MAX_LEVERAGE = 5e18;
    uint constant balanceToBorrowThreshold = 12e17;

    uint lenderID = 5;
    address lender = cheats.addr(lenderID);

    uint treasuryID = 6;
    address treasury = cheats.addr(treasuryID);

    uint borrowFee = 3e15;

    // Test ERC20 Tokens
    WETH weth;
    TestERC20 erc20;

    // LTokens
    LEther lEthImplementation;
    LEther lEth;

    LToken lErc20Implementation;
    LToken lErc20;

    // Core Contracts
    RiskEngine riskEngine;

    // Registry Proxy
    Registry registryImplementation;
    IRegistry registry;

    // Account Manager Proxy
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
        // emit log_uint(block.number);

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
        registry.init();

        oracle = new OracleFacade();
        rateModel = new DefaultRateModel(
            1 * 1e17,
            3 * 1e17,
            35 * 1e17,
            2102400 * 1e18
        );
        controller = new ControllerFacade();
        riskEngine = new RiskEngine(registry);

        // Account Manager deployment
        accountManagerImplementation = new AccountManager();
        accountManager = IAccountManager(
            address(new Proxy(address(accountManagerImplementation)))
        );
        accountManager.init(registry);

        beacon = new Beacon(address(new Account()));
        accountFactory = new AccountFactory(address(beacon));

        lEthImplementation = new LEther();
        lEth = LEther(payable(address(new Proxy(address(lEthImplementation)))));
        lEth.init(weth, "LEther", "LEth", registry, borrowFee, treasury);

        lErc20Implementation = new LToken();
        lErc20 = LToken(address(new Proxy(address(lErc20Implementation))));
        lErc20.init(erc20, "LTestERC20", "LERC20", registry, borrowFee, treasury);
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
        riskEngine.initDep();
        accountManager.initDep();
        lEth.initDep('RATE_MODEL');
        lErc20.initDep('RATE_MODEL');

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

    function mintWETH(address account, uint amt) public {
        uint senderID = 10;
        address sender = cheats.addr(senderID);
        cheats.deal(sender, amt);

        cheats.startPrank(sender);
        weth.deposit{value: amt}();
        weth.transfer(account, amt.mulWadDown(borrowFee));
        cheats.stopPrank();
    }

    function borrow(
        address owner,
        address account,
        address token,
        uint amt
    )
        internal returns (uint borrowAmtAfterFee)
    {
        if (token == address(weth)) {
            cheats.deal(lender, amt);
            cheats.prank(lender);
            lEth.depositEth{value: amt}();
            cheats.prank(owner);
            accountManager.borrow(account, token, amt);
        } else {
            erc20.mint(lender, amt);
            cheats.startPrank(lender);
            erc20.approve(address(lErc20), type(uint).max);
            lErc20.deposit(amt, lender);
            cheats.stopPrank();

            cheats.prank(owner);
            accountManager.borrow(account, token, amt);
        }
        borrowAmtAfterFee = amt - amt.mulWadDown(borrowFee);
    }

    function isContract(address _contract) internal view returns (bool size) {
        assembly { size := gt(extcodesize(_contract), 0x0) }
    }
}
