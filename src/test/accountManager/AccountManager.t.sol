// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract AccountManagerTest is TestBase {

    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
    }

    // Opening and closing accounts

    function testOpenAccount(address _owner) public {
        // Test
        address account = openAccount(_owner);

        // Assert
        assertEq(userRegistry.accountsOwnedBy(_owner).length, 1);
        assertEq(userRegistry.ownerFor(account), _owner);
        assertEq(IAccount(account).accountManager(), address(accountManager));
        assertEq(IAccount(account).activationBlock(), block.number);
    }

    function testOpenAccountReuse(address[2] calldata owners) public {
        // Setup
        address account = openAccount(owners[0]);
        cheats.roll(block.number + 1);
        cheats.prank(owners[0]);
        accountManager.closeAccount(account);

        // Test
        testOpenAccount(owners[1]);
    }

    function testCloseAccount() public {
        // Setup
        address account = openAccount(owner);
        cheats.roll(block.number + 1);

        // Test
        cheats.prank(owner);
        accountManager.closeAccount(account);

        // Assert
        assertEq(userRegistry.accountsOwnedBy(owner).length, 0);
        assertEq(accountManager.getInactiveAccounts()[0], account);
    }

    function testCloseAccountDeactivationError() public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.AccountDeactivationFailure.selector);
        accountManager.closeAccount(account);
    }

    function testCloseAccountOwnerOnlyError() public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.closeAccount(account);
    }

    function testCloseAccountOutstandingDebtError() public {
        // Setup
        address account = openAccount(owner);
        deposit(owner, account, address(erc20), 10);
        borrow(owner, account, address(erc20), 10);
        cheats.roll(block.number + 1);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.OutstandingDebt.selector);
        accountManager.closeAccount(account);
    }

    // Deposit Eth

    function testDepositEthOnlyOwnerError(
        uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.depositEth{value: value}(account);
    }

    // Withdraw Eth

    function testWithdrawEthOnlyOwnerError(
        uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.withdrawEth(account, value);
    }

    function testWithdrawEthRiskThresholdBreachedError(
        uint96 value
    ) public {
        cheats.assume(value != 0);

        // Setup
        address account = openAccount(owner);
        deposit(owner, account, address(0), value);
        borrow(owner, account, address(0), value);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.withdrawEth(account, value);
    }

    // Deposit

    function testDepositOnlyOwnerError(
        address token, uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.deposit(account, token, value);
    }

    function testDepositCollateralTypeRestrictedError(
        address token, uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.CollateralTypeRestricted.selector);
        accountManager.deposit(account, token, value);
    }

    // Withdraw

    function testWithdrawOnlyOwnerError(
        address token, uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.withdraw(account, token, value);
    }

    function testWithdrawRiskThresholdBreachedError(
        uint96 value
    ) public {
        cheats.assume(value != 0);

        // Setup
        address account = openAccount(owner);
        deposit(owner, account, address(erc20), value);
        borrow(owner, account, address(erc20), value);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.withdraw(account, address(erc20), value);
    }

    // Borrow

    function testBorrowOnlyOwnerError(
        address token, uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.borrow(account, token, value);
    }

    function testBorrowLTokenUnavailableError(
        address token, uint96 value
    ) public {
        cheats.assume(token != address(0));
        
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.LTokenUnavailable.selector);
        accountManager.borrow(account, token, value);
    }

    function testBorrowRiskThresholdError(
        uint96 value
    ) public {
        cheats.assume(value != 0);
        
        // Setup
        address account = openAccount(owner);
        deposit(owner, account, address(erc20), value);
        erc20.mint(accountManager.LTokenAddressFor(address(erc20)), value);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.borrow(account, address(erc20), uint(5)*value);
    }

    // Repay

    function testRepayOnlyOwnerError(
        address token, uint96 value
    ) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.repay(account, token, value);
    }

    function testRepayLTokenUnavailableError(
        address token, uint96 value
    ) public {
        cheats.assume(token != address(0));
        
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.LTokenUnavailable.selector);
        accountManager.repay(account, token, value);
    }

    // Liquidate

    function testLiquidateAccountNotLiquidatableError() public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountNotLiquidatable.selector);
        accountManager.liquidate(account);
    }

    // Approve

    function testApproveOnlyOwnerError(address spender, address token, uint96 value) public {
        // Setup
        address account = openAccount(owner);

        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.approve(account, token, spender, value);
    }

    // Settle
    
    function testSettle(uint96 value) public {
        cheats.assume(value != 0);
        // Setup
        address account = openAccount(owner);
        deposit(owner, account, address(erc20), value);
        deposit(owner, account, address(0), value);
        borrow(owner, account, address(erc20), value);
        borrow(owner, account, address(0), value);

        // Test
        cheats.prank(owner);
        accountManager.settle(account);

        assertEq(account.balance, value);
        assertEq(erc20.balanceOf(account), value);
        assertEq(address(lEth).balance, value);
        assertEq(erc20.balanceOf(address(lErc20)), value);
    } 

}