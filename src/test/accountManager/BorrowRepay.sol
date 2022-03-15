// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

contract AccountManagerBorrowRepayTest is TestBase {
    address account;
    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    function testBorrow(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(depositAmt * MAX_LEVERAGE > borrowAmt);
        deposit(owner, account, address(erc20), depositAmt);
        erc20.mint(accountManager.LTokenAddressFor(address(erc20)), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.borrow(account, address(erc20), borrowAmt);

        // Assert
        assertEq(erc20.balanceOf(account), uint(depositAmt) + uint(borrowAmt));
    }

    function testBorrowEth(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(depositAmt * MAX_LEVERAGE > borrowAmt);
        deposit(owner, account, address(0), depositAmt);
        cheats.deal(accountManager.LTokenAddressFor(address(0)), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.borrow(account, address(0), borrowAmt);
        assertEq(account.balance, uint(depositAmt) + uint(borrowAmt));
    }

    function testBorrowRiskEngineError(
        uint96 depositAmt,
        uint96 borrowAmt
    ) 
        public
    {
        // Setup
        cheats.assume(depositAmt != 0 && borrowAmt != 0);
        cheats.assume(borrowAmt > MAX_LEVERAGE * depositAmt);
        deposit(owner, account, address(erc20), depositAmt);
        erc20.mint(accountManager.LTokenAddressFor(address(erc20)), borrowAmt);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.borrow(account, address(erc20), borrowAmt);
    }

    function testBorrowEthRiskEngineError(
        uint96 depositAmt,
        uint96 borrowAmt
    ) 
        public
    {
        // Setup
        cheats.assume(depositAmt != 0 && borrowAmt != 0);
        cheats.assume(borrowAmt > MAX_LEVERAGE * depositAmt);
        deposit(owner, account, address(0), depositAmt);
        cheats.deal(accountManager.LTokenAddressFor(address(0)), borrowAmt);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.borrow(account, address(0), borrowAmt);
    }

    function testBorrowAuthError(address token, uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.borrow(account, token, value);
    }

    function testBorrowLTokenUnavailableError(
        address token,
        uint96 value
    )
        public 
    {
        // Setup
        cheats.assume(token != address(0));

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.LTokenUnavailable.selector);
        accountManager.borrow(account, token, value);
    }

    // Repay
    function testRepayAuthError(address token, uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.repay(account, token, value);
    }

    function testRepayLTokenUnavailableError(
        address token,
        uint96 value
    )
        public
    {
        // Setup
        cheats.assume(token != address(0));

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.LTokenUnavailable.selector);
        accountManager.repay(account, token, value);
    }
}