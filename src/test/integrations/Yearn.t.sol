// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {YTokenOracle} from "oracle/yearn/YTokenOracle.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";
import {YearnVaultController} from "controller/yearn/YearnController.sol";

contract YearnIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address yearnVault = 0xE537B5cc158EB71037D4125BDD7538421981E6AA;

    YearnVaultController yearnController;
    YTokenOracle yTokenOracle;

    function setupYearnController() internal {
        yearnController = new YearnVaultController();
        controller.updateController(yearnVault, yearnController);

        yTokenOracle = new YTokenOracle(oracle);
        oracle.setERC20Oracle(yearnVault, yTokenOracle);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupCurveController();
        setupYearnController();
        setupWethController();
        account = openAccount(user);
    }

    function testVaultDeposit(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);
        depositCurveLiquidity(account, amt, user);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "deposit(uint256)",
            IERC20(crv3crypto).balanceOf(account)
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, crv3crypto, yearnVault, type(uint).max);
        accountManager.exec(account, yearnVault, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(crv3crypto).balanceOf(account), 0);
        assertGt(IERC20(yearnVault).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), yearnVault);
    }

    function testVaultWithdraw(uint64 amt) public {
        // Setup
        testVaultDeposit(amt);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "withdraw(uint256)",
            IERC20(yearnVault).balanceOf(account)
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, yearnVault, yearnVault, type(uint).max);
        accountManager.exec(account, yearnVault, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(yearnVault).balanceOf(account), 0);
        assertGt(IERC20(crv3crypto).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), crv3crypto);
    }
}