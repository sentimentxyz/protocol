// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "forge-std/console.sol";
import {IVault, IAsset} from "controller/balancer/IVault.sol";
import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {ArbiIntegrationTestBase} from "./utils/ArbiIntegrationTestBase.sol";
import {ComposableStableBalancerLPOracle} from "oracle/balancer/ComposableStableBalancerLPOracle.sol";
import {WeightedBalancerLPOracle} from "oracle/balancer/WeightedBalancerLPOracle.sol";
import {IVault as IVaultOracle} from "oracle/balancer/IVault.sol";
import {BalancerController} from "controller/balancer/BalancerController.sol";
import {BalancerLPStakingController} from "controller/balancer/BalancerLPStakingController.sol";
import {Stable2CurveGaugeOracle} from "oracle/curve/Stable2CurveGaugeOracle.sol";
import {ZeroOracle} from "oracle/zero/ZeroOracle.sol";

enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        REMOVE_TOKEN
}
enum SwapKind { GIVEN_IN, GIVEN_OUT }

contract BalancerArbiIntegrationTest is ArbiIntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address constant LDO = 0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60;

    address balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address BPTWBTCWETHUSDC = 0x64541216bAFFFEec8ea535BB71Fbc927831d0595;
    bytes32 BPTWBTCWETHUSDCPoolID = 0x64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002;
    address BPTWBTCWETHUSDCGauge = 0x104f1459a2fFEa528121759B238BB609034C2f01;

    address BPTWSTETHWETH = 0xFB5e6d0c1DfeD2BA000fBC040Ab8DF3615AC329c;
    bytes32 BPTWSTETHWETHPoolID = 0xfb5e6d0c1dfed2ba000fbc040ab8df3615ac329c000000000000000000000159;

    address BPTWSTETHUSDC = 0x178E029173417b1F9C8bC16DCeC6f697bC323746;
    bytes32 BPTWSTETHUSDCPoolID = 0x178e029173417b1f9c8bc16dcec6f697bc323746000200000000000000000158;
    address BPTWSTETHUSDCGauge = 0x9232EE56ab3167e2d77E491fBa82baBf963cCaCE;

    BalancerController balancerController;
    ComposableStableBalancerLPOracle stableBalancerOracle;
    WeightedBalancerLPOracle weightedBalancerOracle;
    BalancerLPStakingController balancerStakingController;
    Stable2CurveGaugeOracle balancerStakingOracle;
    ZeroOracle zeroOracle;

    function setupBalancerController() internal {
        accountManager.toggleCollateralStatus(USDC);
        balancerController = new BalancerController();
        controller.updateController(balancerVault, balancerController);

        balancerStakingController = new BalancerLPStakingController();
        controller.updateController(BPTWBTCWETHUSDCGauge, balancerStakingController);
        controller.updateController(BPTWSTETHUSDCGauge, balancerStakingController);

        stableBalancerOracle = new ComposableStableBalancerLPOracle(oracle, IVaultOracle(balancerVault));
        oracle.setOracle(BPTWSTETHWETH, stableBalancerOracle);
        controller.toggleTokenAllowance(BPTWSTETHWETH);

        weightedBalancerOracle = new WeightedBalancerLPOracle(oracle, IVaultOracle(balancerVault));
        oracle.setOracle(BPTWBTCWETHUSDC, weightedBalancerOracle);
        oracle.setOracle(BPTWSTETHUSDC, weightedBalancerOracle);
        controller.toggleTokenAllowance(BPTWBTCWETHUSDC);
        controller.toggleTokenAllowance(BPTWSTETHUSDC);

        balancerStakingOracle = new Stable2CurveGaugeOracle(oracle);
        oracle.setOracle(BPTWSTETHUSDCGauge, balancerStakingOracle);
        oracle.setOracle(BPTWBTCWETHUSDCGauge, balancerStakingOracle);
        controller.toggleTokenAllowance(BPTWSTETHUSDCGauge);
        controller.toggleTokenAllowance(BPTWBTCWETHUSDCGauge);

        zeroOracle = new ZeroOracle();
        oracle.setOracle(LDO, zeroOracle);
        controller.toggleTokenAllowance(LDO);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupWethController();
        setupBalancerController();
        setupWSTETHOracle();
        setupChainLinkOracles();
        account = openAccount(user);
    }

    function testVaultJoinBPTWBTCWETHUSDCPool(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deal(WETH, user, amt, true);
        startHoax(user);
        IERC20(WETH).approve(address(accountManager), type(uint).max);
        accountManager.deposit(account, WETH, amt);

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(WBTC);
        assets[1] = IAsset(WETH);
        assets[2] = IAsset(USDC);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 0;
        amounts[1] = amt;
        amounts[2] = 0;

        // Encode calldata
        bytes memory data = abi.encodeWithSelector(
            0xb95cac28,
            BPTWBTCWETHUSDCPoolID,
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
        accountManager.approve(account, WETH, balancerVault, type(uint).max);
        accountManager.exec(account, balancerVault, 0, data);

        // Assert
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertGt(IERC20(BPTWBTCWETHUSDC).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), BPTWBTCWETHUSDC);
    }

    function testBPTWBTCWETHUSDCStaking(uint64 amt) public {
        testVaultJoinBPTWBTCWETHUSDCPool(amt);

        bytes memory data = abi.encodeWithSelector(
            0xb6b55f25,
            IERC20(BPTWBTCWETHUSDC).balanceOf(account)
        );

        accountManager.approve(account, BPTWBTCWETHUSDC, BPTWBTCWETHUSDCGauge, type(uint).max);
        accountManager.exec(account, BPTWBTCWETHUSDCGauge, 0, data);

        assertEq(IERC20(BPTWBTCWETHUSDC).balanceOf(account), 0);
        assertGt(IERC20(BPTWBTCWETHUSDCGauge).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), BPTWBTCWETHUSDCGauge);
    }

    function testVaultJoinBPTWSTETHUSDCPool(uint24 amt) public {
        // Setup
        cheats.assume(amt > 1e6);
        deal(USDC, user, amt, true);
        startHoax(user);
        IERC20(USDC).approve(address(accountManager), type(uint).max);
        accountManager.deposit(account, USDC, amt);

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(WSTETH);
        assets[1] = IAsset(USDC);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = amt;

        // Encode calldata
        bytes memory data = abi.encodeWithSelector(
            0xb95cac28,
            BPTWSTETHUSDCPoolID,
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
        accountManager.approve(account, USDC, balancerVault, type(uint).max);
        accountManager.exec(account, balancerVault, 0, data);

        // Assert
        assertEq(IERC20(USDC).balanceOf(account), 0);
        assertGt(IERC20(BPTWSTETHUSDC).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), BPTWSTETHUSDC);
    }

    function testStakingBPTWSTETHUSDC(uint24 amt) public {
        testVaultJoinBPTWSTETHUSDCPool(amt);

        bytes memory data = abi.encodeWithSelector(
            0xb6b55f25,
            IERC20(BPTWSTETHUSDC).balanceOf(account)
        );

        accountManager.approve(account, BPTWSTETHUSDC, BPTWSTETHUSDCGauge, type(uint).max);
        accountManager.exec(account, BPTWSTETHUSDCGauge, 0, data);

        assertEq(IERC20(BPTWSTETHUSDC).balanceOf(account), 0);
        assertGt(IERC20(BPTWSTETHUSDCGauge).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), BPTWSTETHUSDCGauge);
    }

    function testClaimStakingRewardsBPTWSTETHUSDC(uint24 amt) public {
        testStakingBPTWSTETHUSDC(amt);

        bytes memory data = abi.encodeWithSelector(0xe6f1daf2);

        accountManager.exec(account, BPTWSTETHUSDCGauge, 0, data);

        assertEq(IERC20(BPTWSTETHUSDC).balanceOf(account), 0);
        assertGt(IERC20(BPTWSTETHUSDCGauge).balanceOf(account), 0);
        assertGt(IERC20(LDO).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), BPTWSTETHUSDCGauge);
        assertEq(IAccount(account).assets(1), BAL);
        assertEq(IAccount(account).assets(2), LDO);
    }

    function testVaultJoinBPTWSTETHWETHPool(uint64 amt) public {
        // Setup
        accountManager.toggleCollateralStatus(WSTETH);
        cheats.assume(amt > 1e8);
        deal(WETH, user, amt, true);
        deal(WSTETH, user, amt, true);
        startHoax(user);
        IERC20(WETH).approve(address(accountManager), type(uint).max);
        accountManager.deposit(account, WETH, amt);

        IERC20(WSTETH).approve(address(accountManager), type(uint).max);
        accountManager.deposit(account, WSTETH, amt);

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(WSTETH);
        assets[1] = IAsset(WETH);
        assets[2] = IAsset(BPTWSTETHWETH);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = amt;
        amounts[1] = amt;
        amounts[2] = 0;

        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = amt;
        amountsIn[1] = amt;

        // Encode calldata
        bytes memory data = abi.encodeWithSelector(
            0xb95cac28,
            BPTWSTETHWETHPoolID,
            account,
            account,
            IVault.JoinPoolRequest(
                assets,
                amounts,
                abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0),
                false
            )
        );

        // Test
        accountManager.approve(account, WETH, balancerVault, type(uint).max);
        accountManager.approve(account, WSTETH, balancerVault, type(uint).max);
        accountManager.exec(account, balancerVault, 0, data);

        // Assert
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertEq(IERC20(WSTETH).balanceOf(account), 0);
        assertGt(IERC20(BPTWSTETHWETH).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), BPTWSTETHWETH);
    }

    function testVaultExitBPTWSTETHWETHPool(uint64 amt) public {
        // Setup
        testVaultJoinBPTWSTETHWETHPool(amt);

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(WSTETH);
        assets[1] = IAsset(WETH);
        assets[2] = IAsset(BPTWSTETHWETH);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 0;
        amounts[1] = 1;
        amounts[2] = 0;

        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = amt;
        amountsIn[1] = amt;

        // Encode calldata
        bytes memory data = abi.encodeWithSelector(
            0x8bdb3913,
            BPTWSTETHWETHPoolID,
            account,
            account,
            IVault.ExitPoolRequest(
                assets,
                amounts,
                abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,IERC20(BPTWSTETHWETH).balanceOf(account),1),
                false
            )
        );

        // Test
        accountManager.approve(account, BPTWSTETHWETH, balancerVault, type(uint).max);
        accountManager.exec(account, balancerVault, 0, data);

        // Assert
        assertGt(IERC20(WETH).balanceOf(account), 0);
        assertEq(IERC20(WSTETH).balanceOf(account), 0);
        assertEq(IERC20(BPTWSTETHWETH).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), WETH);
    }
}