// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestBase} from "../utils/TestBase.sol";
import {LToken} from "../../tokens/LToken.sol";
import {Registry} from "../../core/Registry.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {AccountManager} from "../../core/AccountManager.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract RepayFlowTest is TestBase {
    using FixedPointMathLib for uint;
    address public account;
    address public borrower = cheats.addr(1);

    address public account2;
    address public borrower2 = cheats.addr(15);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
        account2 = openAccount(borrower2);
    }

    function testRepayEth(uint96 depositAmt, uint96 borrowAmt, uint96 repayAmt)
        public
    {
        // Setup
        cheats.assume(borrowAmt > repayAmt && repayAmt > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(borrower, account, address(0), depositAmt);
        borrow(borrower, account, address(weth), borrowAmt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(weth), repayAmt);

        // Assert
        assertEq(
            riskEngine.getBalance(account),
            uint(depositAmt) + borrowAmt - repayAmt
        );
        assertEq(riskEngine.getBorrows(account), borrowAmt - repayAmt);
    }

    function testRepayERC20(uint96 depositAmt, uint96 borrowAmt, uint96 repayAmt)
        public
    {
        // Setup
        cheats.assume(borrowAmt > repayAmt && repayAmt > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), repayAmt);

        // Assert
        assertEq(
            riskEngine.getBalance(account),
            uint(depositAmt) + borrowAmt - repayAmt
        );
        assertEq(riskEngine.getBorrows(account), borrowAmt - repayAmt);
    }

    function testMaxRepayWETH(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(borrower, account, address(0), depositAmt);
        borrow(borrower, account, address(weth), borrowAmt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(weth), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
    }

    function testMaxRepayERC20(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
    }

    function testMaxRepayERC20WithInterest(uint96 depositAmt, uint48 borrowAmt1, uint48 borrowAmt2)
        public
    {
        // Setup
        cheats.assume(borrowAmt1 > 0 && borrowAmt2 > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt1 + borrowAmt2)
            .divWadDown(uint(borrowAmt1) + borrowAmt2) >
            riskEngine.balanceToBorrowThreshold()
        );
        erc20.mint(lender, type(uint96).max);
        cheats.startPrank(lender);
        erc20.approve(address(lErc20), type(uint).max);
        lErc20.deposit(uint(borrowAmt1) + uint(borrowAmt2), lender);
        cheats.stopPrank();


        deposit(borrower, account, address(erc20), depositAmt);
        cheats.prank(borrower);
        accountManager.borrow(account, address(erc20), borrowAmt1);

        cheats.roll(block.number + 100);

        deposit(borrower2, account2, address(erc20), depositAmt);
        cheats.prank(borrower2);
        accountManager.borrow(account2, address(erc20), borrowAmt2);

        cheats.roll(block.number + 100);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        cheats.prank(borrower2);
        accountManager.repay(account2, address(erc20), type(uint).max);

        assertEq(lErc20.getBorrowBalance(account), 0);
        assertEq(lErc20.getBorrowBalance(account2), 0);
        assertEq(lErc20.getBorrows(), 0);
    }
}