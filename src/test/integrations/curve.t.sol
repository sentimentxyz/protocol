// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStableSwapPool} from "@controller/src/curve/IStableSwapPool.sol";

contract curveIntegrationTest is TestBase {

    address user = cheats.addr(1);
    address account;

    function setUp() public {
        setupContracts();
        setUpWEthController();
        setupCurveController();
        account = openAccount(user);
    }

    function testSwap(uint8 value) public {
        // Setup
        cheats.assume(value != 0);
        cheats.deal(user, value);
        deposit(user, account, address(0), value);

        // Wrap Eth
        bytes memory wethdata = abi.encodeWithSignature("deposit()");
        cheats.prank(user);
        accountManager.exec(account, WETH, value, wethdata);
        
        uint256 minValue = IStableSwapPool(curveEthSwap).get_dy(uint(0), uint(2), value);
        emit log_uint(minValue);
        // address coin1 = IStableSwapPool(curveEthSwap).coins(0);
        // emit log_address(coin1);
        bytes memory data = abi.encodeWithSignature(
            "exchange(uint256,uint256,uint256,uint256)",
            2,
            0,
            value,
            minValue
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, curveEthSwap, value, data);

        // Assert
        assertEq(IERC20(USDT).balanceOf(account), value);
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), USDT);
    }
}