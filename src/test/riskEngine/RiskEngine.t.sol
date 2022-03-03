// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

contract RiskEngineTest is TestBase {

    address owner = cheats.addr(1);
    address account;

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    function testIsBorrowAllowedNoBalance(uint96 value) public {
        cheats.assume(value != 0);

        // Test
        bool isBorrowAllowed = riskEngine.isBorrowAllowed(account, address(erc20), value);

        // Assert
        assertTrue(!isBorrowAllowed);
    }

    function testIsBorrowAllowed(uint8 multiplier, uint96 value) public {
        cheats.assume(value != 0);

        // Setup
        deposit(owner, account, address(erc20), value);

        // Test
        bool isBorrowAllowed = riskEngine.isBorrowAllowed(account, address(erc20), uint(multiplier) * value);

        // Assert
        if (multiplier <= 4) assertTrue(isBorrowAllowed);
        else assertTrue(!isBorrowAllowed);
    }

    function testisWithdrawAllowedNoDebt(address token, uint96 value) public {
        // Test
        bool isWithdrawAllowed = riskEngine.isWithdrawAllowed(account, token, value);

        // Assert
        assertTrue(isWithdrawAllowed);
    }

    function testisWithdrawAllowedDebt(uint8 divider, uint96 value) public {
        cheats.assume(value != 0 && divider != 0);

        // Setup
        deposit(owner, account, address(erc20), value);
        borrow(owner, account, address(erc20), value);

        // Test
        bool isWithdrawAllowed = riskEngine.isWithdrawAllowed(account, address(erc20), value/divider);

        // Assert
        if (divider < 2) assertTrue(!isWithdrawAllowed);
        else assertTrue(isWithdrawAllowed);
    }

    // Admin
    
    function testSetAccountManagerAddress(address _accountManager) public {
        // Test
        riskEngine.setAccountManagerAddress(_accountManager);

        // Assert
        assertEq(address(riskEngine.accountManager()), _accountManager);
    }

    function testSetAccountManagerAddressAdminOnlyError(address caller, address _accountManager) public {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        riskEngine.setAccountManagerAddress(_accountManager);

        // Assert
        assertEq(address(riskEngine.accountManager()), address(accountManager));
    }
}