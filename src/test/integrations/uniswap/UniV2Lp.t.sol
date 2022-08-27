// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {UniV2LpOracle} from "oracle/uniswap/UniV2LPOracle.sol";
import {IntegrationTestBase} from "../utils/IntegrationTestBase.sol";
import {UniV2Controller} from "controller/uniswap/UniV2Controller.sol";
import {IUniV2Factory} from "controller/uniswap/IUniV2Factory.sol";

contract UniV2LpIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant WETH_USDT_LP = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
    address constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    UniV2Controller uniV2Controller;
    UniV2LpOracle uniLPOracle;

    function setupUniV2Controller() private {
        uniV2Controller = new UniV2Controller(WETH, IUniV2Factory(FACTORY), controller);
        controller.updateController(UNIV2_ROUTER, uniV2Controller);
        controller.toggleTokenAllowance(WETH_USDT_LP);

        uniLPOracle = new UniV2LpOracle(oracle);
        oracle.setOracle(WETH_USDT_LP, uniLPOracle);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupUniV2Controller();
        setupWethController();
        setupCurveController();

        account = openAccount(user);
    }

    // All tests use the USDT/WETH Uni v2 pool

    function testAddLiquidity(uint64 amt) public {
        // WETH/USDT

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), uint(2) * amt);
        wrapEth(account, amt, user);
        swapEthUsdt(amt, account, user);
        uint amtUsdt = IERC20(USDT).balanceOf(account);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)",
            WETH, USDT, amt, amtUsdt, 0, 0, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, UNIV2_ROUTER, type(uint).max);
        accountManager.approve(account, USDT, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertGt(IERC20(WETH_USDT_LP).balanceOf(account), 0);
    }

    function testAddLiquidityEth(uint64 amt) public {
        // ETH/USDT

        // Setup
        cheats.assume(amt > 1 ether);
        deposit(user, account, address(0), uint(2) * amt);
        swapEthUsdt(amt, account, user);
        uint amtUsdt = IERC20(USDT).balanceOf(account);

         // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "addLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
            USDT, amtUsdt, 0, 0, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, amt, data);
        cheats.stopPrank();

        // Assert
        assertGt(IERC20(WETH_USDT_LP).balanceOf(account), 0);
    }

    function testRemoveLiquidity(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1 ether);
        testAddLiquidity(amt);
        uint lpTokens = IERC20(WETH_USDT_LP).balanceOf(account);

        // Encode Calldata
        bytes memory data = abi.encodeWithSignature(
            "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)",
            WETH, USDT, lpTokens, 0, 0, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH_USDT_LP, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertGt(IERC20(WETH).balanceOf(account), 0);
        assertGt(IERC20(USDT).balanceOf(account), 0);
        assertEq(IERC20(WETH_USDT_LP).balanceOf(account), 0);
    }

    function testRemoveLiquidityEth(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1 ether);
        testAddLiquidity(amt);
        uint lpTokens = IERC20(WETH_USDT_LP).balanceOf(account);

        // Encode Calldata
        bytes memory data = abi.encodeWithSignature(
            "removeLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
            USDT, lpTokens, 0, 0, account, 1893456000);

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH_USDT_LP, UNIV2_ROUTER, type(uint).max);
        accountManager.exec(account, UNIV2_ROUTER, 0, data);
        cheats.stopPrank();

        // Assert
        assertGt(account.balance, 0);
        assertEq(IERC20(WETH_USDT_LP).balanceOf(account), 0);
        assertGt(IERC20(USDT).balanceOf(account), 0);
    }

}