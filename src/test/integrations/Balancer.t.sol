// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {IVault} from "controller/balancer/IVault.sol";
import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";
import {StableBalancerLPOracle, IVault as IVault2} from "oracle/balancer/StableBalancerLPOracle.sol";
import {WeightedBalancerLPOracle, IVault as IVault3} from "oracle/balancer/BalancerLPOracle.sol";
import "controller/balancer/BalancerController.sol";

enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }

contract BalancerIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address balancerStablePool = 0x06Df3b2bbB68adc8B0e302443692037ED9f91b42;
    address balancerWeightedPool = 0x96646936b91d6B9D7D0c47C496AfBF3D6ec7B6f8;

    BalancerController balancerController;
    StableBalancerLPOracle stableBalancerOracle;
    WeightedBalancerLPOracle weightedBalancerOracle;

    function setupBalancerController() internal {
        balancerController = new BalancerController(controller);
        controller.updateController(balancerVault, balancerController);
        controller.toggleTokenAllowance(balancerStablePool);
        controller.toggleTokenAllowance(balancerWeightedPool);

        stableBalancerOracle = new StableBalancerLPOracle(oracle, IVault2(balancerVault));
        weightedBalancerOracle = new WeightedBalancerLPOracle(oracle, IVault3(balancerVault));
        oracle.setOracle(balancerStablePool, stableBalancerOracle);
        oracle.setOracle(balancerWeightedPool, weightedBalancerOracle);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupWethController();
        setupCurveController();
        setupBalancerController();
        account = openAccount(user);
    }

    function testVaultJoinStablePool(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        swapEthUsdt(amt, account, user);
        uint usdtAmount = IERC20(USDT).balanceOf(account);

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        assets[1] = IAsset(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        assets[2] = IAsset(0xdAC17F958D2ee523a2206206994597C13D831ec7);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = usdtAmount;

        // Encode calldata
        bytes memory data = abi.encodeWithSelector(
            0xb95cac28,
            0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000063,
            account,
            account,
            IVault.JoinPoolRequest(
                assets,
                amounts,
                abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amounts, 0),
                false
            )
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, balancerVault, type(uint).max);
        accountManager.exec(account, balancerVault, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(USDT).balanceOf(account), 0);
        assertGt(IERC20(balancerStablePool).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), balancerStablePool);
    }

    function testVaultJoinWeightedPool() public {
        // Setup
        uint amt = 1e18;
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(USDC);
        assets[1] = IAsset(address(0));

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = amt;

        // Encode calldata
        bytes memory data = abi.encodeWithSelector(
            0xb95cac28,
            0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019,
            account,
            account,
            IVault.JoinPoolRequest(
                assets,
                amounts,
                abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amounts, 0),
                false
            )
        );

        // Test
        cheats.startPrank(user);
        accountManager.exec(account, balancerVault, amt, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(USDT).balanceOf(account), 0);
        assertGt(IERC20(balancerWeightedPool).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), balancerWeightedPool);
    }
}