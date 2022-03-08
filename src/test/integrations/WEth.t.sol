// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccountManager} from "../../interface/core/IAccountManager.sol";

contract WEthIntegrationTest is TestBase {

    address user = cheats.addr(1);
    address account;

    function setUp() public {
        setupContracts();
        setUpWEthController();
        account = openAccount(user);
    }

    function testWrapEth(uint8 value) public {
        // Setup
        cheats.assume(value != 0);
        cheats.deal(user, value);
        deposit(user, account, address(0), value);
        bytes memory data = abi.encodeWithSignature("deposit()");

        // Test
        cheats.prank(user);
        accountManager.exec(account, WETH, value, data);

        // Assert
        assertEq(IERC20(WETH).balanceOf(account), value);
        assertEq(account.balance, 0);
        assertEq(IAccount(account).assets(0), WETH);
    }

    function testUnwrapEth(uint8 value) public {
        // Setup
        testWrapEth(value);
        bytes memory data = abi.encodeWithSignature(
            "withdraw(uint256)", value
        );

        // Test
        cheats.prank(user);
        accountManager.exec(account, WETH, 0, data);

        // Assert
        assertEq(IERC20(WETH).balanceOf(account), 0);
        assertEq(account.balance, value);
        assertEq(IAccount(account).getAssets().length, 0);
    }

    function testWEthSigError(uint8 value, bytes4 signature) public {
        // Setup
        bytes memory data = abi.encodeWithSelector(signature);

        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.FunctionCallRestricted.selector);
        accountManager.exec(account, WETH, value, data);
    }
}