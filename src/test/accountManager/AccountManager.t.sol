// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IControllerFacade} from "@controller/src/core/IControllerFacade.sol";

contract AccountManagerTest is TestBase {
    address account;
    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

     // Approve
    function testApproveAuthError(
        address spender,
        address token,
        uint96 value
    )
        public
    {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.approve(account, token, spender, value);
    }

    // Liquidate
    function testLiquidateHealthyAccount(
        uint96 depositAmt,
        uint borrowAmt
    ) 
        public 
    {
        // Setup
        cheats.assume(depositAmt * MAX_LEVERAGE > borrowAmt);
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(0), borrowAmt);

        // Test
        cheats.expectRevert(Errors.AccountNotLiquidatable.selector);
        accountManager.liquidate(account);
    }

    // Settle
    function testSettle(uint96 value) public {
        // Setup
        cheats.assume(value != 0);
        deposit(owner, account, address(erc20), value);
        deposit(owner, account, address(0), value);
        borrow(owner, account, address(erc20), value);
        borrow(owner, account, address(0), value);

        // Test
        cheats.prank(owner);
        accountManager.settle(account);

        // Assert
        assertEq(account.balance, value);
        assertEq(erc20.balanceOf(account), value);
        assertEq(address(lEth).balance, value);
        assertEq(erc20.balanceOf(address(lErc20)), value);
    }

    function testSettleAuthError() public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.settle(account);
    }
}