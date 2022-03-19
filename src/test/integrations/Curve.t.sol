// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";
import {CurveCryptoSwapController} 
    from "@controller/src/curve/CurveCryptoSwapController.sol";

interface IStableSwapPool {    
    function get_dy(uint256, uint256, uint256) external view returns (uint256);
}


contract CurveIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);
    address constant tricryptoPool = 0x960ea3e3C7FB317332d990873d354E18d7645590;

    CurveCryptoSwapController curveController;

    function setUp() public {
        setupContracts();
        setupWethController();
        setupCurveController();
        account = openAccount(user);
    }

    function setupCurveController() private {
        curveController = new CurveCryptoSwapController(controller);
        controller.updateController(tricryptoPool, curveController);
        controller.toggleSwapAllowance(USDT);
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

        // Encode Calldata
        bytes memory data = abi.encodeWithSignature(
            "exchange(uint256,uint256,uint256,uint256,bool)",
            uint256(2), // WETH
            uint256(0), // USDT
            amt,
            minValue,
            true
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, tricryptoPool, amt, data);

        // Assert
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), USDT);
        assertGe(IERC20(USDT).balanceOf(account), minValue);
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