// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract RepayInParts is TestBase {
    using FixedPointMathLib for uint;

    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    // Borrow - Repay - Repay Max
    function testRepayInParts1(uint96 depositAmt, uint96 borrowAmt, uint96 repayAmt)
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
        cheats.roll(block.number + 100);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), repayAmt);

        // Increment block number
        cheats.roll(block.number + 100);

        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }

    // Borrow1 - Borrow2 - Repay Max
    function testRepayInParts2(uint96 depositAmt, uint96 borrowAmt, uint96 borrow1)
        public
    {
        // Setup
        cheats.assume(borrowAmt > borrow1);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );

        // Lending Pool
        address lender = address(5);
        erc20.mint(lender, borrowAmt);
        cheats.startPrank(lender);
        erc20.approve(address(lErc20), type(uint).max);
        lErc20.deposit(borrowAmt, lender);
        cheats.stopPrank();

        deposit(borrower, account, address(erc20), depositAmt);

        // Borrow1
        cheats.startPrank(borrower);
        if (lErc20.previewDeposit(borrow1) > 0)
            accountManager.borrow(account, address(erc20), borrow1);
        cheats.stopPrank();

        cheats.roll(block.number + 10);
        erc20.mint(account, type(uint128).max);

        // Borrow2
        cheats.startPrank(borrower);
        if (lErc20.previewDeposit(borrowAmt - borrow1) > 0)
            accountManager.borrow(account, address(erc20), borrowAmt - borrow1);
        cheats.stopPrank();
        cheats.roll(block.number + 10);

        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }

    // Borrow1 - Borrow2 - Repay1 - Repay Max
    function testRepayInParts3(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 borrow1,
        uint96 repayAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt > repayAmt && repayAmt > 0);
        cheats.assume(borrowAmt > borrow1);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );

        // Lending Pool
        address lender = address(5);
        erc20.mint(lender, borrowAmt);
        cheats.startPrank(lender);
        erc20.approve(address(lErc20), type(uint).max);
        lErc20.deposit(borrowAmt, lender);
        cheats.stopPrank();

        deposit(borrower, account, address(erc20), depositAmt);

        // Borrow1
        cheats.startPrank(borrower);
        if (lErc20.previewDeposit(borrow1) > 0)
            accountManager.borrow(account, address(erc20), borrow1);
        cheats.stopPrank();

        cheats.roll(block.number + 10);
        erc20.mint(account, type(uint128).max);

        // Borrow2
        cheats.startPrank(borrower);
        if (lErc20.previewDeposit(borrowAmt - borrow1) > 0)
            accountManager.borrow(account, address(erc20), borrowAmt - borrow1);
        cheats.stopPrank();
        cheats.roll(block.number + 10);

        // Repay1
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), repayAmt);
        cheats.roll(block.number + 10);

        // Max Repay
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }

    // Borrow1 - Repay1 - Borrow2 - Repay Max
    function testRepayInParts4(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 borrow1
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt > borrow1 && borrow1 > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );

        uint repayAmt = borrow1 / 2;

        cheats.assume(repayAmt > 0);

        // Lending Pool
        address lender = address(5);
        erc20.mint(lender, borrowAmt);
        cheats.startPrank(lender);
        erc20.approve(address(lErc20), type(uint).max);
        lErc20.deposit(borrowAmt, lender);
        cheats.stopPrank();

        deposit(borrower, account, address(erc20), depositAmt);

        // Borrow1
        cheats.startPrank(borrower);
        if (lErc20.previewDeposit(borrow1) > 0)
            accountManager.borrow(account, address(erc20), borrow1);
        cheats.stopPrank();

        cheats.roll(block.number + 10);
        erc20.mint(account, type(uint128).max);

        // Repay1
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), repayAmt);
        cheats.roll(block.number + 10);

        // Borrow2
        cheats.startPrank(borrower);
        if (lErc20.previewDeposit(borrowAmt - borrow1) > 0)
            accountManager.borrow(account, address(erc20), borrowAmt - borrow1);
        cheats.stopPrank();
        cheats.roll(block.number + 10);

        // Max Repay
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }

    function testRepayInParts10()
        public
    {
        // Setup
        uint depositAmt = 5e17;
        uint borrowAmt = 5e17;
        uint repayAmt = 2e17;
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);
        cheats.roll(block.number + 23);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), repayAmt);

        // Increment block number
        cheats.roll(block.number + 15);

        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }
}