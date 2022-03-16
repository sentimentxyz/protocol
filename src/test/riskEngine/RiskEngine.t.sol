// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

contract RiskEngineTest is TestBase {

    address account;
    address owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    function testIsBorrowAllowed(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        deposit(owner, account, address(0), depositAmt);

        // Test
        bool isBorrowAllowed = riskEngine.isBorrowAllowed(
            account,
            address(0),
            borrowAmt
        );

        // Assert
        (MAX_LEVERAGE * depositAmt >= borrowAmt) ?
            assertTrue(isBorrowAllowed)
            : assertFalse(isBorrowAllowed);
    }

    function testIsWithdrawAllowed(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(depositAmt > withdrawAmt);
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(0), borrowAmt);

        // Test
        bool isWithdrawAllowed = riskEngine.isWithdrawAllowed(
            account,
            address(0),
            withdrawAmt
        );

        // Assert
        ( (MAX_LEVERAGE * (depositAmt - withdrawAmt) > borrowAmt) ) ?
            assertTrue(isWithdrawAllowed) : assertFalse(isWithdrawAllowed);
    }

    // Admin
    function testSetAccountManager(address _accountManager) public {
        // Test
        riskEngine.setAccountManagerAddress(_accountManager);

        // Assert
        assertEq(address(riskEngine.accountManager()), _accountManager);
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
        riskEngine.setAccountManagerAddress(_accountManager);

        // Assert
        assertEq(
            address(riskEngine.accountManager()),
            address(accountManager)
        );
    }
}