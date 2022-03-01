// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract AccountTest is TestBase {
    
    IAccount public marginAccount;
    address public accountOwner;

    function setUp() public {
        accountOwner = cheats.addr(1);
        setupContracts();

        cheats.prank(accountOwner);
        marginAccount = IAccount(openAccount(accountOwner));
    }

    function testInitialize() public {
        // Test
        cheats.expectRevert(errors.contractAlreadyInitialized());
        marginAccount.initialize(address(accountManager));
    }

    function testAddAsset(address token) public {
        // Test
        cheats.prank(address(accountManager));
        marginAccount.addAsset(token);

        // Assert
        assertEq(token, marginAccount.getAssets()[0]);
    }

    function testAddAssetError(address token) public {
        // Test
        cheats.expectRevert(errors.accountManagerOnly());
        marginAccount.addAsset(token);
    }

    function testAddBorrow(address token) public {
        // Test
        cheats.prank(address(accountManager));
        marginAccount.addBorrow(token);

        // Assert
        assertEq(token, marginAccount.getBorrows()[0]);
    }

    function testAddBorrowError(address token) public {
        // Test
        cheats.expectRevert(errors.accountManagerOnly());
        marginAccount.addBorrow(token);
    }

    function testRemoveAsset(address token) public {
        // Setup
        testAddAsset(token);

        // Test
        cheats.prank(address(accountManager));
        marginAccount.removeAsset(token);

        // Assert
        assertEq(0, marginAccount.getAssets().length);
    }

    function testRemoveAssetError(address token) public {
        // Test
        cheats.expectRevert(errors.accountManagerOnly());
        marginAccount.removeAsset(token);
    }

    function testRemoveBorrow(address token) public {
        // Setup
        testAddBorrow(token);

        // Test
        cheats.prank(address(accountManager));
        marginAccount.removeBorrow(token);

        // Assert
        assertEq(0, marginAccount.getBorrows().length);
    }

    function testRemoveBorrowError(address token) public {
        // Test
        cheats.expectRevert(errors.accountManagerOnly());
        marginAccount.removeBorrow(token);
    }

    function testHasNoDebt() public {
        // Assert
        assertTrue(marginAccount.hasNoDebt());

        // Setup
        testAddBorrow(address(0));

        // Assert
        assertTrue(marginAccount.hasNoDebt() == false);
    }

    function testSweepTo() public {
        // Setup
        testAddAsset(address(erc20));
        erc20.mint(address(marginAccount), 10);
        cheats.deal(address(marginAccount), 10);

        // Test
        cheats.prank(address(accountManager));
        marginAccount.sweepTo(address(accountOwner));

        // Assert
        assertEq(erc20.balanceOf(address(marginAccount)), 0);
        assertEq(address(marginAccount).balance, 0);
        assertEq(erc20.balanceOf(accountOwner), 10);
        assertEq(accountOwner.balance, 10);
    }

    function testSweepToError() public {
        // Test
        cheats.expectRevert(errors.accountManagerOnly());
        marginAccount.sweepTo(address(accountOwner));
    }
}