// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Utils} from "../utils/Utils.sol";
import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IUserRegistry} from "../../interface/core/IUserRegistry.sol";

contract UserRegistryTest is TestBase {

    event UpdateAccountManagerAddress(address indexed accountManager);

    function setUp() public {
        setupContracts();
    }

    function testUpdateAccount(address account, address owner) public {
        // Test
        cheats.prank(address(accountManager));
        userRegistry.updateAccount(account, owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), owner);
    }

    function testUpdateAccountError(address account, address owner) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        userRegistry.updateAccount(account, owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), address(0));
    }

    function testAddAccount(address account, address owner) public {
        // Test
        cheats.prank(address(accountManager));
        userRegistry.addAccount(account, owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), owner);
        address[] memory accounts = userRegistry.getAllAccounts();
        assertTrue(Utils.isPresent(accounts, account));
    }

    function testAddAccountError(address account, address owner) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        userRegistry.addAccount(account, owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), address(0));
        assertEq(userRegistry.getAllAccounts().length, 0);
    }

    function testCloseAccount(address account, address owner) public {
        // Setup
        testAddAccount(account, owner);

        // Test
        cheats.prank(address(accountManager));
        userRegistry.closeAccount(account);

        // Assert
        assertEq(userRegistry.ownerFor(account), address(0));
    }

    function testCloseAccountError(address account, address owner) public {
        // Setup
        testAddAccount(account, owner);

        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        userRegistry.closeAccount(account);

        // Assert
        assertEq(userRegistry.ownerFor(account), owner);
    }

    function testAccountsOwnedBy(address account_1, address account_2, address account_3, address owner) public {
        // Setup
        cheats.startPrank(address(accountManager));
        testAddAccount(account_1, owner);
        testAddAccount(account_2, owner);
        testAddAccount(account_3, owner);

        // Test
        address[] memory accounts = userRegistry.accountsOwnedBy(owner);

        // Assert
        assertTrue(Utils.isPresent(accounts, account_1));
        assertTrue(Utils.isPresent(accounts, account_2));
        assertTrue(Utils.isPresent(accounts, account_3));
    }

    function testSetAccountManagerAddress(address _accountManager) public {
        // Test
        userRegistry.setAccountManagerAddress(_accountManager);

        // Assert
        assertEq(userRegistry.accountManager(), _accountManager);
    }

    function testSetAccountManagerAddressError(address caller, address _accountManager) public {
        // Test
        cheats.expectRevert(Errors.AdminOnly.selector);
        cheats.prank(caller);
        userRegistry.setAccountManagerAddress(_accountManager);

        // Assert
        assertEq(userRegistry.accountManager(), address(accountManager));
    }
}