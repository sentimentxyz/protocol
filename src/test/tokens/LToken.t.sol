// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

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

        (
            uint principal,
            uint interestIndex
        ) = lErc20.borrowBalanceFor(account);

        // Assert
        assertTrue(isFirstBorrow);
        assertEq(principal, lendAmt);
        assertEq(interestIndex, lErc20.borrowIndex());
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
        cheats.prank(address(accountManager));
        bool isBorrowBalanceZero = lErc20.collectFrom(account, collectAmt);

        (
            uint principal,
            uint interestIndex
        ) = lErc20.borrowBalanceFor(account);

        // Assert
        assertEq(principal, lendAmt - collectAmt);
        assertEq(interestIndex, lErc20.borrowIndex());
        assertTrue(isBorrowBalanceZero == (lendAmt == collectAmt));
    }

    function testFailCollectFrom(uint lendAmt, uint liquidity, uint collectAmt) 
        public 
    {
        // Setup
        cheats.assume(collectAmt > lendAmt);
        testLendTo(lendAmt, liquidity);

        // Test
        cheats.prank(address(accountManager));
        lErc20.collectFrom(account, collectAmt);
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

    function testGetExchangeRate(
        uint96 lendAmt, 
        uint96 liquidity, 
        uint96 delta
    ) 
        public 
    {
        // Setup
        testLendTo(lendAmt, liquidity);
        cheats.roll(block.number + delta);

        // Test
        uint exchangeRate = lErc20.getExchangeRate();

        // Assert
        assertGe(exchangeRate, lErc20.exchangeRate());
    }

    // Admin
    function testSetAccountManager(address _accountManager) public {
        // Test
        lErc20.setAccountManager(_accountManager);

        // Assert
        assertEq(lErc20.accountManager(), _accountManager);
    }

    function testSetAccountManagerAuthError(
        address caller,
        address _accountManager
    ) 
        public 
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        lErc20.setAccountManager(_accountManager);

        // Assert
        assertEq(lErc20.accountManager(), address(accountManager));
    }

    function testSetRateModel(address _rateModel) public {
        // Test
        lErc20.setRateModel(_rateModel);

        // Assert
        assertEq(lErc20.rateModel(), _rateModel);
    }

    function testSetRateModelAuthError(address caller, address _rateModel) 
        public
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        lErc20.setRateModel(_rateModel);

        // Assert
        assertEq(lErc20.rateModel(), address(rateModel));
    }
}