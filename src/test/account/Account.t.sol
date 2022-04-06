// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract AccountTest is TestBase {
    
    IAccount public account;
    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = IAccount(openAccount(owner));
    }

    function testInitialize() public {
        // Test
        cheats.expectRevert(Errors.ContractAlreadyInitialized.selector);
        account.initialize(address(accountManager));
    }

    function testAddAsset(address token) public {
        // Test
        cheats.prank(address(accountManager));
        account.addAsset(token);

        // Assert
        assertEq(token, account.getAssets()[0]);
    }

    function testAddAssetError(address token) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        account.addAsset(token);
    }

    function testAddBorrow(address token) public {
        // Test
        cheats.prank(address(accountManager));
        account.addBorrow(token);

        // Assert
        assertEq(token, account.getBorrows()[0]);
    }

    function testAddBorrowError(address token) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        account.addBorrow(token);
    }

    function testRemoveAsset(address token) public {
        // Setup
        testAddAsset(token);

        // Test
        cheats.prank(address(accountManager));
        account.removeAsset(token);

        // Assert
        assertEq(0, account.getAssets().length);
    }

    function testRemoveAssetError(address token) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        account.removeAsset(token);
    }

    function testRemoveBorrow(address token) public {
        // Setup
        testAddBorrow(token);

        // Test
        cheats.prank(address(accountManager));
        account.removeBorrow(token);

        // Assert
        assertEq(0, account.getBorrows().length);
    }

    function testRemoveBorrowError(address token) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        account.removeBorrow(token);
    }

    function testHasNoDebt(address token) public {
        // Assert
        assertTrue(account.hasNoDebt());

        // Setup
        testAddBorrow(token);

        // Assert
        assertTrue(account.hasNoDebt() == false);
    }

    function testSweepTo(address user, uint96 amt) public {
        // Setup
        cheats.assume(amt != 0 && !isContract(user));
        testAddAsset(address(erc20));
        erc20.mint(address(account), amt);
        cheats.deal(address(account), amt);

        // Test
        cheats.prank(address(accountManager));
        account.sweepTo(address(user));

        // Assert
        assertEq(erc20.balanceOf(address(account)), 0);
        assertEq(address(account).balance, 0);
        assertEq(erc20.balanceOf(address(user)), amt);
        assertGe(address(user).balance, amt);
    }

    function testSweepToError(address user) public {
        // Test
        cheats.expectRevert(Errors.AccountManagerOnly.selector);
        account.sweepTo(address(user));
    }
}