// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "./utils/TestBase.sol";
import {IAccount} from "../interface/core/IAccount.sol";

contract BorrowingFlowTest is TestBase {
    address public borrower = cheats.addr(1);
    IAccount public account;

    function setUp() public {
        setupContracts();
    }

    function testDepositCollateralETH(uint96 amt) public {
        // Setup
        account = IAccount(openAccount(borrower));
        cheats.deal(borrower, amt);

        // Test
        cheats.prank(borrower);
        accountManager.depositEth{value: amt}(address(account));

        // Assert
        assertEq(borrower.balance, 0);
        assertEq(address(account).balance, amt);
        assertEq(riskEngine.getBalance(address(account)), amt);
        assertTrue(account.hasNoDebt());
    }

    function testBorrowETH(uint96 amt) public {
        // Setup
        testDepositCollateralETH(amt);
        cheats.deal(address(lEth), amt);

        // Test
        cheats.prank(borrower);
        accountManager.borrow(address(account), address(0), amt);

        // Assert
        assertEq(address(lEth).balance, 0);
        assertEq(address(account).balance, uint(2) * amt);
        assertEq(lEth.getBorrowBalance(address(account)), amt);
    }

    function testDepositCollateralERC20(uint96 amt) public {
        // Setup
        account = IAccount(openAccount(borrower));
        erc20.mint(borrower, amt);

        // Test
        cheats.startPrank(borrower);
        erc20.approve(address(accountManager), type(uint).max);
        accountManager.deposit(address(account), address(erc20), amt);
        cheats.stopPrank();

        // Assert
        assertEq(erc20.balanceOf(borrower), 0);
        assertEq(erc20.balanceOf(address(account)), amt);
        assertEq(riskEngine.getBalance(address(account)), amt); // 1 ERC20 = 1 ETH
        assertTrue(account.hasNoDebt());   
    }

    function testBorrowERC20(uint96 amt) public {
        // Setup
        testDepositCollateralERC20(amt);
        erc20.mint(address(lErc20), amt);

        // Test
        cheats.prank(borrower);
        accountManager.borrow(address(account), address(erc20), amt);

        // Assert
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(erc20.balanceOf(address(account)), uint(2) * amt);
        assertEq(lErc20.getBorrowBalance(address(account)), amt);
    }
}