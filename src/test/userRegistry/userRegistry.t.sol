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
        cheats.startPrank(address(accountManager));
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
        cheats.startPrank(address(accountManager));
        userRegistry.addAccount(account, owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), owner);
        address[] memory accounts = userRegistry.getAccounts();
        assertTrue(Utils.isPresent(accounts, account));
    }

    function testAddAccountError(address account, address owner) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        userRegistry.addAccount(account, owner);

        // Assert
        assertEq(userRegistry.ownerFor(account), address(0));
        assertEq(userRegistry.getAccounts().length, 0);
    }

    function testCloseAccount(address account, address owner) public {
        // Setup
        cheats.startPrank(address(accountManager));
        testAddAccount(account, owner);

        // Test
        userRegistry.closeAccount(account);
        cheats.stopPrank();

        // Assert
        assertEq(userRegistry.ownerFor(account), address(0));
    }

    function testCloseAccountError(address account, address owner) public {
        // Setup
        cheats.prank(address(accountManager));
        testAddAccount(account, owner);
        cheats.stopPrank();

        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        userRegistry.closeAccount(account);

        // Assert
        assertEq(userRegistry.ownerFor(account), owner);
    }

    function testAccountsOwnedBy(address[] memory accounts, address owner) public {
        // Setup
        cheats.startPrank(address(accountManager));
        for(uint i = 0; i < accounts.length; i++) {
            testAddAccount(accounts[i], owner);
        }

        // Test
        address[] memory userAccounts = userRegistry.accountsOwnedBy(owner);

        // Assert
        uint numberOfAccounts = 0;
        for(
            uint i = 0;
            i < userAccounts.length && userAccounts[i] != address(0);
            i++
        ) {
            numberOfAccounts++;
            assertTrue(Utils.isPresent(accounts, userAccounts[i]));
        }
        assertEq(numberOfAccounts, accounts.length);

    }

    function testSetAccountManagerAddress(address _accountManager) public {
        // Setup
        cheats.expectEmit(true, false, false, false);
        emit UpdateAccountManagerAddress(_accountManager);

        // Test
        cheats.prank(address(this));
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