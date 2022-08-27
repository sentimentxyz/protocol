// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Errors} from "../../../utils/Errors.sol";
import {IERC20} from "../../../interface/tokens/IERC20.sol";
import {IAccount} from "../../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "../utils/IntegrationTestBase.sol";
import {StableSwap3PoolController} from "controller/curve/StableSwap3PoolController.sol";

interface IStableSwapPool {
    function get_dy(int128, int128, uint256) external view returns (uint256);
}

contract CurveStableSwapIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    address pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    StableSwap3PoolController stableSwapController;

    function setupStableSwapController() private {
        stableSwapController = new StableSwap3PoolController();
        controller.updateController(pool, stableSwapController);
        controller.toggleTokenAllowance(DAI);
    }

    function setUp() public {
        setupContracts();
        setupOracles();
        setupWethController();
        setupCurveController();
        setupStableSwapController();
        account = openAccount(user);
    }

    function testSwapUSDTDAI(uint64 amt) public {
        // Setup
        cheats.assume(amt > 1e8 gwei); // min exchange amt 0.1 eth
        deposit(user, account, address(0), amt);
        swapEthUsdt(amt, account, user);

        uint usdtBalance = IERC20(USDT).balanceOf(account);

        uint256 minValue = IStableSwapPool(pool).get_dy(
            2, // USDT
            0, // DAI
            usdtBalance
        );

        // Encode calldata
        bytes memory data = abi.encodeWithSignature(
            "exchange(int128,int128,uint256,uint256)",
            2, // USDT
            0, // DAI
            usdtBalance,
            minValue
        );

        // Test
        cheats.startPrank(user);
        accountManager.approve(account, USDT, pool, usdtBalance);
        accountManager.exec(account, pool, 0, data);

        // Assert
        assertGe(IERC20(DAI).balanceOf(account), minValue);
        assertEq(IERC20(USDT).balanceOf(account), 0);
        assertEq(IAccount(account).assets(0), DAI);

    }

    function testSwapSigError(uint64 amt, bytes4 sig) public {
        // Setup
        bytes memory data = abi.encodeWithSelector(sig);

        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.FunctionCallRestricted.selector);
        accountManager.exec(account, pool, amt, data);
    }
}