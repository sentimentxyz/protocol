// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

        address[] memory accounts = userRegistry.accountsOwnedBy(owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), owner);
        assertEq(account, accounts[accounts.length - 1]); // Since it's always inserted at the end
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

    function testAccountsOwnedBy(address[3] calldata accounts, address owner) public {
        // Setup
        testAddAccount(accounts[0], owner);
        testAddAccount(accounts[1], owner);
        testAddAccount(accounts[2], owner);

        // Test
        address[] memory accountsFromRegistry = userRegistry.accountsOwnedBy(owner);

        // Assert
        assertEq(accounts[0], accountsFromRegistry[0]);
        assertEq(accounts[1], accountsFromRegistry[1]);
        assertEq(accounts[2], accountsFromRegistry[2]);
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