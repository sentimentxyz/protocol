// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract BorrowFlowTest is TestBase {
    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testBorrowETH(uint96 amt) public {
        // Test
        deposit(borrower, account, address(0), amt);
        borrow(borrower, account, address(0), amt);

        // Assert
        assertEq(address(lEth).balance, 0);
        assertEq(account.balance, uint(2) * amt);
        assertEq(lEth.getBorrowBalance(address(account)), amt);
    }

    function testBorrowERC20(uint96 amt) public {
        // Test
        deposit(borrower, account, address(erc20), amt);
        borrow(borrower, account, address(erc20), amt);

        // Assert
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(erc20.balanceOf(address(account)), uint(2) * amt);
        assertEq(lErc20.getBorrowBalance(address(account)), amt);
    }
}