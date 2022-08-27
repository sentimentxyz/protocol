// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Errors} from "../../utils/Errors.sol";
import {IERC20} from "../../interface/tokens/IERC20.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IntegrationTestBase} from "./utils/IntegrationTestBase.sol";
import {IAccountManager} from "../../interface/core/IAccountManager.sol";

contract WethIntegrationTest is IntegrationTestBase {
    address account;
    address user = cheats.addr(1);

    function setUp() public {
        setupContracts();
        setupOracles();
        setupWethController();
        account = openAccount(user);
    }

    function testWrapEth(uint96 amt) public {
        // Setup
        deposit(user, account, address(0), amt);
        bytes memory data = abi.encodeWithSignature("deposit()");

        // Test
        cheats.prank(user);
        accountManager.exec(account, WETH, amt, data);

        // Assert
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), WETH);
        assertEq(IERC20(WETH).balanceOf(account), amt);
    }

    function testUnwrapEth(uint96 amt) public {
        // Setup
        testWrapEth(amt);
        bytes memory data = abi.encodeWithSignature(
            "withdraw(uint256)", amt
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, WETH, 0, data);

        // Assert
        assertEq(account.balance, amt);
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertEq(IAccount(account).getAssets().length, 0);
    }

    function testWethSigError(uint96 amt, bytes4 sig) public {
        // Setup
        bytes memory data = abi.encodeWithSelector(sig);

        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.FunctionCallRestricted.selector);
        accountManager.exec(account, WETH, amt, data);
    }
}