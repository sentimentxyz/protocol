// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Errors} from "../../../utils/Errors.sol";
import {ATokenOracle} from "oracle/aave/ATokenOracle.sol";
import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {IAccount} from "../../../interface/core/IAccount.sol";
import {ArbiIntegrationTestBase} from "../utils/ArbiIntegrationTestBase.sol";
import {AaveV3Controller} from "controller/aave/AaveV3Controller.sol";
import {IPoolAddressProvider} from "./interface/IPoolAddressProvider.sol";

/// @notice runs only on arbitrum
contract AaveV3ArbiIntegrationTest is ArbiIntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    IPoolAddressProvider addressProvider =
        IPoolAddressProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);
    address aWeth = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;
    address aDai = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;
    address pool;

    ATokenOracle aTokenOracle;
    AaveV3Controller aaveController;

    function setupAaveController() internal {
        aTokenOracle = new ATokenOracle(oracle);
        oracle.setOracle(aWeth, aTokenOracle);
        oracle.setOracle(aDai, aTokenOracle);

        aaveController = new AaveV3Controller(controller);
        controller.updateController(pool, aaveController);
        controller.updateController(pool, aaveController);
        controller.toggleTokenAllowance(aWeth);
    }

    function setUp() public {
        pool = addressProvider.getPool();
        setupContracts();
        setupOracles();
        setupAaveController();
        setupWethController();
        account = openAccount(user);
    }

    function testDepositWeth(uint64 amt) public {
        cheats.assume(amt > 1e8 gwei);
        // Setup
        deposit(user, account, address(0), amt);
        wrapEth(account, amt, user);
        uint value = IERC20(WETH).balanceOf(account);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "supply(address,uint256,address,uint16)",
            WETH,
            value,
            account,
            0
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, pool, value);
        accountManager.exec(account, pool, 0, data);
        cheats.stopPrank();

        // Assert
        assertGt(IERC20(aWeth).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), aWeth);
    }

    function testWithdrawWeth(uint64 amt) public {
        // Setup
        testDepositWeth(amt);

        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "withdraw(address,uint256,address)",
            WETH,
            type(uint256).max,
            account
        );

        // Test
        cheats.startPrank(user);
        accountManager.exec(account, pool, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(aWeth).balanceOf(account), 0);
        assertGt(IERC20(WETH).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), WETH);
    }

    function testDepositDaiError(uint64 amt) public {
        // Encode call data
        bytes memory data = abi.encodeWithSignature(
            "supply(address,uint256,address,uint16)",
            aDai,
            amt,
            account,
            0
        );

        // Test
        cheats.startPrank(user);
        cheats.expectRevert(Errors.FunctionCallRestricted.selector);
        accountManager.exec(account, pool, 0, data);
        cheats.stopPrank();
    }
}