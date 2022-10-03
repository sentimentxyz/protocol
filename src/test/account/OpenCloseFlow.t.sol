// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract OpenCloseFlowTest is TestBase {
    address public account;
    address public user = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(user);
    }

    function testOpen() public {
        // Assert
        assertTrue(IAccount(account).hasNoDebt());
        assertEq(riskEngine.getBalance(account), 0);
        assertEq(riskEngine.getBorrows(account), 0);
        assertTrue(riskEngine.isAccountHealthy(account));
        assertEq(account, registry.accountsOwnedBy(user)[0]);
        assertEq(address(accountManager), IAccount(account).accountManager());
    }

    function testClose() public {
        // Setup
        cheats.roll(block.number + 1);

        // Test
        cheats.prank(user);
        accountManager.closeAccount(account);

        // Assert
        assertEq(registry.accountsOwnedBy(user).length, 0);
        assertEq(accountManager.getInactiveAccountsOf(user).length, 1);
        assertEq(address(accountManager), IAccount(account).accountManager());
        assertEq(0, IAccount(account).activationBlock());
    }

    function testReassign() public {
        // Setup
        testClose();

        // Test
        address account2 = openAccount(user);

        // Assert
        assertEq(account, account2);
        assertEq(account, registry.accountsOwnedBy(user)[0]);
        assertEq(accountManager.getInactiveAccountsOf(user).length, 0);
        assertEq(address(accountManager), IAccount(account).accountManager());
    }

    function testCloseAccountOutstandingDebtError(uint96 value) public {
        // Setup
        cheats.assume(value > 10 ** (18 - 2));
        deposit(user, account, address(erc20), value);
        borrow(user, account, address(erc20), value);
        cheats.roll(block.number + 1);

        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.OutstandingDebt.selector);
        accountManager.closeAccount(account);
    }

    function testCloseAccountOwnerOnlyError() public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.closeAccount(account);
    }

    function testCloseAccountDeactivationError() public {
        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.AccountDeactivationFailure.selector);
        accountManager.closeAccount(account);
    }

     function testOpenAccountZeroAddressError() public {
        // Test
        cheats.prank(user);
        cheats.expectRevert(Errors.ZeroAddress.selector);
        accountManager.openAccount(address(0));
    }
}