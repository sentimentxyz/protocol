// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../../utils/Errors.sol";
import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {CTokenOracle} from "oracle/compound/CTokenOracle.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";
import {CompoundController} from "controller/compound/CompoundController.sol";

interface ICERC20 {
    function exchangeRateCurrent() external returns (uint);
}

contract CompoundIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address constant cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address constant cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;

    CTokenOracle cTokenOracle;
    CompoundController compoundController;

    function setupCompoundController() internal {
        compoundController = new CompoundController();
        controller.updateController(cEth, compoundController);
        controller.updateController(cUSDT, compoundController);

        cTokenOracle = new CTokenOracle(oracle, cEth);
        oracle.setOracle(cEth, cTokenOracle);
        oracle.setOracle(cUSDT, cTokenOracle);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupCompoundController();
        setupCurveController();
        account = openAccount(user);
    }

    function testDepositEth(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Encode call data
        bytes memory data = abi.encodeWithSignature("mint()");

        // Fetching exchange rate
        uint exchange_rate = ICERC20(cEth).exchangeRateCurrent();

        // Test
        cheats.prank(user);
        accountManager.exec(account, cEth, amt, data);

        // Assert
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), cEth);
        assertLe(IERC20(cEth).balanceOf(account), (amt/(exchange_rate/1e18)));
    }

    function testDepositERC20(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Swap Eth for USDT
        swapEthUsdt(amt, account, user);
        uint usdtAmount = IERC20(USDT).balanceOf(account);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "mint(uint256)",
            usdtAmount
        );

        // Fetch exchange rate
        uint exchange_rate = ICERC20(cUSDT).exchangeRateCurrent();

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, cUSDT, usdtAmount);
        accountManager.exec(account, cUSDT, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IAccount(account).assets(0), cUSDT);
        assertLe(
            IERC20(cUSDT).balanceOf(account),
            (usdtAmount*1e18/(exchange_rate))
        );
    }

    function testRedeemCToken(uint64 amt) public {
        // Setup
        testDepositEth(amt);
        cheats.roll(block.number + 100);

        // Encode call data
        uint cEthBalance = IERC20(cEth).balanceOf(account);
        bytes memory data = abi.encodeWithSignature(
            "redeem(uint256)",
            cEthBalance
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, cEth, cEth, cEthBalance);
        accountManager.exec(account, cEth, 0, data);
        cheats.stopPrank();

        // Assert
        assertGe(account.balance, amt);
    }
}