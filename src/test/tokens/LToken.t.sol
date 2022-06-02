// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {console} from "../utils/console.sol";

contract LTokenTest is TestBase {

    address account;
    address owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    function testLendTo(uint lendAmt, uint liquidity) public {
        // Setup
        cheats.assume(lendAmt <= liquidity);
        erc20.mint(address(lErc20), liquidity);

        // Test
        cheats.prank(address(accountManager));
        bool isFirstBorrow = lErc20.lendTo(account, lendAmt);

        uint borrowBalance = lErc20.getBorrowBalance(account);

        // Assert
        assertTrue(isFirstBorrow);
        assertEq(borrowBalance, lendAmt);
    }

    function testFailLendTo(uint lendAmt, uint liquidity) public {
        // Setup
        cheats.assume(lendAmt > liquidity);
        erc20.mint(address(lErc20), liquidity);

        // Test
        cheats.prank(address(accountManager));
        lErc20.lendTo(account, lendAmt);
    }

    function testLendToAuthError(uint lendAmt) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        lErc20.lendTo(account, lendAmt);
    }

    function testCollectFrom(uint lendAmt, uint liquidity, uint collectAmt)
        public
    {
        // Setup
        cheats.assume(collectAmt <= lendAmt);
        testLendTo(lendAmt, liquidity);

        // Test
        cheats.startPrank(address(accountManager));
        bool isBorrowBalanceZero = lErc20.collectFrom(account, collectAmt);
        cheats.stopPrank();

        uint borrowBalance = lErc20.getBorrowBalance(account);

        // Assert
        assertEq(borrowBalance, lendAmt - collectAmt);
        assertTrue(isBorrowBalanceZero == (lendAmt == collectAmt));
    }

    function testFailCollectFrom(uint lendAmt, uint liquidity, uint collectAmt)
        public
    {
        // Setup
        cheats.assume(collectAmt > lendAmt);
        testLendTo(lendAmt, liquidity);

        // Test
        cheats.startPrank(address(accountManager));
        lErc20.collectFrom(account, collectAmt);
        cheats.stopPrank();
    }

    function testCollectFromAuthError(uint lendAmt) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        lErc20.collectFrom(account, lendAmt);
    }

    function testGetBorrowBalance(
        uint96 liquidity,
        uint96 borrowAmt,
        uint96 delta
    )
        public
    {
        // Setup
        testLendTo(borrowAmt, liquidity);
        cheats.roll(block.number + delta);

        // Test
        uint borrowBalance = lErc20.getBorrowBalance(account);

        // Assert
        assertGe(borrowBalance, borrowAmt);
    }

    function testInitialize() public {
        // Setup
        assertEq(address(registry), address(lErc20.registry()));

        // Test
        accountManager.initDep();

        // Assert
        assertEq(address(rateModel), address(lErc20.rateModel()));
        assertEq(address(accountManager), address(lErc20.accountManager()));
    }

    function testInitializeAuthError(address caller) public {
        cheats.assume(caller != lErc20.admin());
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        lErc20.initDep('RATE_MODEL');
    }
}