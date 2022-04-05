// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";

interface IStableSwapPool {    
    function get_dy(uint256, uint256, uint256) external view returns (uint256);
}

contract CurveIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    function setUp() public {
        setupContracts();
        setupWethController();
        setupCurveController();
        account = openAccount(user);
    }

    function testSwapWethUsdt(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei); // min exchange amt 0.1 eth
        deposit(user, account, address(0), amt);

        // Wrap Eth
        cheats.prank(user);
        accountManager.exec(
            account,
            WETH,
            amt,
            abi.encodeWithSignature("deposit()")
        );

        // Compute expected amt received after the swap
        uint256 minValue = IStableSwapPool(tricryptoPool).get_dy(
            uint256(2), // WETH
            uint256(0), // USDT
            amt
        );

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "exchange(uint256,uint256,uint256,uint256,bool)",
            uint256(2), // WETH
            uint256(0), // USDT
            amt,
            minValue,
            false
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, tricryptoPool, amt);
        accountManager.exec(account, tricryptoPool, 0, data);

        // Assert
        assertGe(IERC20(USDT).balanceOf(account), minValue);
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), USDT);
    }

    function testSwapEthUsdt(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei); // min exchange amt 0.1 eth
        deposit(user, account, address(0), amt);

        // Compute expected amt received after the swap
        uint256 minValue = IStableSwapPool(tricryptoPool).get_dy(
            uint256(2), // WETH
            uint256(0), // USDT
            amt
        );

        // Test
        swapEthUsdt(amt, account, user);

        // Assert
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), USDT);
        assertGe(IERC20(USDT).balanceOf(account), minValue);
    }

    function testDepositEth(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei); // min exchange amt 0.1 eth
        deposit(user, account, address(0), amt);

        // Wrap Eth
        cheats.prank(user);
        accountManager.exec(
            account,
            WETH,
            amt,
            abi.encodeWithSignature("deposit()")
        );

        // Encode Calldata 
        bytes memory data = abi.encodeWithSignature(
            "add_liquidity(uint256[3],uint256)",
            [0, 0, amt],
            0
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, WETH, tricryptoPool, amt);
        accountManager.exec(account, tricryptoPool, 0, data);
        cheats.stopPrank();

        // Assert
        assertTrue(IERC20(crv3crypto).balanceOf(account) > 0);
        assertEq(IAccount(account).assets(0), crv3crypto);
    }

    function testWithdrawEth(uint64 amt) public {
        // Setup
        testDepositEth(amt);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "remove_liquidity(uint256,uint256[3])",
            IERC20(crv3crypto).balanceOf(account),
            [0, 0, 1]
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, crv3crypto, tricryptoPool, amt);
        accountManager.exec(account, tricryptoPool, 0, data);
        
        // Assert
        assertTrue(IERC20(WETH).balanceOf(account) > 0);
        assertEq(IAccount(account).assets(0), WETH);
    }

    function testWithdrawOnlyEth(uint64 amt) public {
        // Setup
        testDepositEth(amt);

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "remove_liquidity_one_coin(uint256,uint256,uint256)",
            IERC20(crv3crypto).balanceOf(account),
            2,
            1
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, crv3crypto, tricryptoPool, amt);
        accountManager.exec(account, tricryptoPool, 0, data);
        
        // Assert
        assertTrue(IERC20(WETH).balanceOf(account) > 0);
        assertEq(IAccount(account).assets(0), WETH);
    }

    function testSwapSigError(uint64 amt, bytes4 sig) public {
        // Setup
        bytes memory data = abi.encodeWithSelector(sig);

        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.FunctionCallRestricted.selector);
        accountManager.exec(account, tricryptoPool, amt, data);
    }
}