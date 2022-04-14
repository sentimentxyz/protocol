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

    function testBorrowEth(uint96 depositAmt, uint96 borrowAmt) public {
        // Test
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        deposit(borrower, account, address(0), depositAmt);
        borrow(borrower, account, address(weth), borrowAmt);

        // Assert
        assertEq(address(lEth).balance, 0);
        assertEq(riskEngine.getBalance(account), uint(depositAmt) + borrowAmt);
        assertTrue(!IAccount(account).hasNoDebt());
        assertEq(lEth.getBorrowBalance(address(account)), borrowAmt);
    }

    function testBorrowERC20(uint96 depositAmt, uint96 borrowAmt) public {
        // Test
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);

        // Assert
        assertTrue(!IAccount(account).hasNoDebt());
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(lErc20.getBorrowBalance(address(account)), borrowAmt);
        assertEq(
            erc20.balanceOf(address(account)), 
            uint(depositAmt) + borrowAmt
        );
    }
}