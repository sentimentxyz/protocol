// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {IntegrationTestBase} from "../utils/IntegrationTestBase.sol";
import {UniV2Controller} from "controller/uniswap/UniV2Controller.sol";

contract UniV2SwapIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Path Arrays
    address[] wethToUsdt = [WETH, USDT];
    address[] usdtToWeth = [USDT, WETH];

    UniV2Controller uniV2Controller;

    function setupUniV2Controller() private {
        uniV2Controller = new UniV2Controller(controller);
        controller.updateController(UNIV2_ROUTER, uniV2Controller);
        controller.toggleTokenAllowance(WETH);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupUniV2Controller();
        setupWethController();
        setupCurveController();
        account = openAccount(user);
    }

    // All swaps are between ETH / USDT or WETH / USDT

    function testSwapExactTokensForTokens(uint64 amt) public {
        // WETH -> USDT

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), amt);
        wrapEth(account, amt, user);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            amt, 0, wethToUsdt, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertGe(IERC20(USDT).balanceOf(account), 0);
    }

    function testSwapTokensForExactTokens(uint64 amt) public {
        // WETH -> USDT
        uint amountOut = 1000 * 1e6; // 1k USDC

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), amt);
        wrapEth(account, amt, user);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)",
            amountOut, amt, wethToUsdt, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertGe(IERC20(WETH).balanceOf(account), 0);
        assertEq(IERC20(USDT).balanceOf(account), amountOut);
    }

    function testSwapExactEthForTokens(uint64 amt) public {
        // ETH -> USDT

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), amt);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "swapExactETHForTokens(uint256,address[],address,uint256)",
            0, wethToUsdt, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, amt, data);
        cheats.stopPrank();

        // Assert
        assertEq(account.balance, 0);
        assertGt(IERC20(USDT).balanceOf(account), 0);
    }

    function testSwapEthForExactTokens(uint64 amt) public {
        // ETH -> USDT
        uint amountOut = 1000 * 1e6; // 1k USDC

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), amt);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "swapETHForExactTokens(uint256,address[],address,uint256)",
            amountOut, wethToUsdt, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, amt, data);
        cheats.stopPrank();

        // Assert
        assertGe(account.balance, 0);
        assertEq(IERC20(USDT).balanceOf(account), amountOut);
    }

    function testSwapExactTokensForEth(uint64 amt) public {
        // USDT -> ETH

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), amt);
        swapEthUsdt(amt, account, user);
        uint amtUsdt = IERC20(USDT).balanceOf(account);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
            amtUsdt, 0, usdtToWeth, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertGt(account.balance, 0);
        assertEq(IERC20(USDT).balanceOf(account), 0);
    }

    function testSwapTokensForExactEth(uint64 amt) public {
        // USDT -> ETH
        uint amountOut = 1 ether;

        // Setup
        cheats.assume(amt > 15e9 gwei); // 1.5 ETH
        deposit(user, account, address(0), amt);
        swapEthUsdt(amt, account, user);
        uint amtUsdt = IERC20(USDT).balanceOf(account);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "swapTokensForExactETH(uint256,uint256,address[],address,uint256)",
            amountOut, amtUsdt, usdtToWeth, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertGe(account.balance, amountOut);
    }
}