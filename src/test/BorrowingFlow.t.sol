// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "./Setup.sol";
import {CheatCode} from "./Cheatcode.sol";
import {DSTest} from "@ds-test/src/test.sol";
import {IAccount} from "../interface/core/IAccount.sol";

contract BorrowingFlowTest is Test {
    
    address user1 = cheatCode.addr(1);

    function setUp() public {
        basicSetup();
        token.mint(user1, 1000);
        
        cheatCode.deal(user1, 1000);
        cheatCode.startPrank(user1);
        
        token.approve(address(ltoken), type(uint).max);
        ltoken.deposit(999);
        
        lEther.deposit{value: 999}();
        cheatCode.stopPrank();
    }

    function testMarginAccountCreation() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        assertEq(IAccount(accounts[0]).owner(), user);
    }

    function testDepost() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        assertEq(marginAccount.balance, 10);
        assertEq(user.balance, 90);

        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);

        assertEq(token.balanceOf(marginAccount), 10);
        assertEq(token.balanceOf(user), 90);
    }

    function testBorrowEth() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        
        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);
        
        accountManager.borrow(marginAccount, address(0), 50);
        
        assertEq(token.balanceOf(marginAccount), 10);
        assertEq(marginAccount.balance, 60);
        assertEq(address(lEther).balance, 949);
    }

    function testBorrow() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        
        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);

        accountManager.borrow(marginAccount, address(token), 49);
        accountManager.borrow(marginAccount, address(0), 50);

        assertEq(token.balanceOf(marginAccount), 59);
        assertEq(marginAccount.balance, 60);
    }

    function testFailBorrow() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        
        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);

        accountManager.borrow(marginAccount, address(token), 100);
    }

    function testRepay() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        
        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);

        accountManager.borrow(marginAccount, address(token), 49);
        accountManager.borrow(marginAccount, address(0), 50);

        accountManager.repay(marginAccount, address(token), 49);
        accountManager.repay(marginAccount, address(0), 50);

        assertEq(token.balanceOf(marginAccount), 10);
        assertEq(marginAccount.balance, 10);
    }

    function testWithdraw() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        
        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);

        accountManager.borrow(marginAccount, address(token), 49);
        accountManager.borrow(marginAccount, address(0), 50);

        accountManager.repay(marginAccount, address(token), 49);
        accountManager.repay(marginAccount, address(0), 50);

        accountManager.withdraw(marginAccount, address(token), 10);
        accountManager.withdrawEth(marginAccount, 10);

        assertEq(user.balance, 100);
        assertEq(token.balanceOf(user), 100);
    }

    function testFailWithdraw() public {
        address user = cheatCode.addr(2);
        accountManager.openAccount(user);
        
        cheatCode.deal(user, 100);
        token.mint(user, 100);
        
        address[] memory accounts = userRegistry.getMarginAccounts(user);
        address marginAccount = accounts[0];
        
        cheatCode.startPrank(user);
        
        accountManager.depositEth{value: 10}(marginAccount);
        
        token.approve(address(accountManager), type(uint).max);
        accountManager.deposit(marginAccount, address(token), 10);

        accountManager.borrow(marginAccount, address(token), 49);
        accountManager.borrow(marginAccount, address(0), 50);

        accountManager.withdraw(marginAccount, address(token), 10);
    }
}