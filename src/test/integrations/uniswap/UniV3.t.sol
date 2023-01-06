// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {IAccount} from "../../../interface/core/IAccount.sol";
import {IntegrationBaseTest} from "../utils/IntegrationBaseTest.sol";
import {ISwapRouterV3} from "controller/uniswap/ISwapRouterV3.sol";
import {UniV3Controller} from "controller/uniswap/UniV3Controller.sol";

contract UniV3IntegrationTest is IntegrationBaseTest {
    address account;
    address user = cheats.addr(1);

    address uniV3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    UniV3Controller uniV3Controller;

    function setupUniV3Controller() private {
        uniV3Controller = new UniV3Controller(controller);
        controller.updateController(uniV3Router, uniV3Controller);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupUniV3Controller();
        setupCurveController();
        setupWethController();
        account = openAccount(user);
    }

    // Swap ETH - ERC20 (ExactOutput)
    function testMultiCallExactOutputSingleEthUSDT(uint64 amt) public {
        // Setup
        uint256 amtOut = 100 * 1e6; // 100 USD
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Encode calldata
        bytes[] memory multiData = new bytes[](2);
        multiData[0] = abi.encodeWithSignature(
            "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactOutputParams(
                WETH,
                USDT,
                account,
                amtOut,
                amt
            )
        );
        multiData[1] = abi.encodeWithSignature("refundETH()");

        bytes memory data = abi.encodeWithSignature(
            "multicall(bytes[])",
            multiData
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, uniV3Router, amt, data);

        // Assert
        assertEq(IERC20(USDT).balanceOf(account), amtOut);
        assertEq(IAccount(account).assets(0), USDT);
        assertTrue(account.balance > 0);
    }

    // Swap ERC20 - ETH (ExactOutput)
    function testMultiCallExactOutputSingleUSDTETH(uint64 amt) public {

        uint256 amtOut = 1e6 gwei;
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Swap Eth for USDT
        swapEthUsdt(amt, account, user);
        uint usdtAmount = IERC20(USDT).balanceOf(account);

        // Encode calldata
        bytes[] memory multiData = new bytes[](2);
        multiData[0] = abi.encodeWithSignature(
            "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactOutputParams(
                USDT,
                WETH,
                uniV3Router,
                amtOut,
                usdtAmount
            )
        );
        multiData[1] = abi.encodeWithSignature(
            "unwrapWETH9(uint256,address)",
            amtOut, account
        );

        bytes memory data = abi.encodeWithSignature(
            "multicall(bytes[])",
            multiData
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, uniV3Router, type(uint).max);
        accountManager.exec(account, uniV3Router, 0, data);

        // Assert
        assertLe(IERC20(USDT).balanceOf(account), usdtAmount);
        assertTrue(account.balance > 0);
    }

    // Swap ERC20 - ETH (ExactInput)
    function testMultiCallExactInputSingleUSDTETH(uint64 amt) public {
        // Setup
        testMultiCallExactOutputSingleEthUSDT(amt);
        uint usdtAmount = IERC20(USDT).balanceOf(account);

        // Encode calldata
        bytes[] memory multiData = new bytes[](2);
        multiData[0] = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactInputParams(
                USDT,
                WETH,
                uniV3Router,
                0,
                usdtAmount
            )
        );
        multiData[1] = abi.encodeWithSignature(
            "unwrapWETH9(uint256,address)",
            1e6 gwei, account
        );

        bytes memory data = abi.encodeWithSignature(
            "multicall(bytes[])",
            multiData
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, uniV3Router, type(uint).max);
        accountManager.exec(account, uniV3Router, 0, data);

        // Assert
        assertGe(IERC20(USDT).balanceOf(account), 0);
        assertLe(account.balance, amt);
        assertEq(IAccount(account).getAssets().length, 0);
    }

    // Swap ERC20 - ERC20 (ExactOutput)
    function testExactOutputSingleWETHUSDT(uint64 amt) public {
        uint256 amtOut = 100 * 1e6; // 100 USD

        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Wrap Eth
        wrapEth(account, amt, user);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactOutputParams(
                WETH,
                USDT,
                account,
                amtOut,
                amt
            )
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, uniV3Router, type(uint).max);
        accountManager.exec(account, uniV3Router, 0, data);

        // Assert
        assertLe(IERC20(USDT).balanceOf(account), amtOut);
        assertTrue(IERC20(WETH).balanceOf(account) > 0);
        assertEq(IAccount(account).getAssets().length, 2);
    }

    // Swap ETH - ERC20 (ExactInput)
    function testExactInputSingleETHUSDT(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactInputParams(
                WETH,
                USDT,
                account,
                0,
                amt
            )
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, uniV3Router, amt, data);

        // Assert
        assertTrue(IERC20(USDT).balanceOf(account) > 0);
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), USDT);
    }

    // Swap ERC20 - ERC20 (ExactInput)
    function testExactInputSingleWETHUSDT(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei);
        deposit(user, account, address(0), amt);
        wrapEth(account, amt, user);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            getExactInputParams(
                WETH,
                USDT,
                account,
                0,
                amt
            )
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, uniV3Router, type(uint).max);
        accountManager.exec(account, uniV3Router, 0, data);

        // Assert
        assertTrue(IERC20(USDT).balanceOf(account) > 0);
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), USDT);
    }


    function getExactOutputParams(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut,
        uint256 amountIn
    )
        private
        pure
        returns (ISwapRouterV3.ExactOutputSingleParams memory data)
    {
        data = ISwapRouterV3.ExactOutputSingleParams(
            tokenIn,
            tokenOut,
            3000,
            recipient,
            amountOut,
            amountIn,
            0
        );
    }

    function getExactInputParams(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut,
        uint256 amountIn
    )
        private
        pure
        returns (ISwapRouterV3.ExactInputSingleParams memory data)
    {
        data = ISwapRouterV3.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            3000,
            recipient,
            amountIn,
            amountOut,
            0
        );
    }
}