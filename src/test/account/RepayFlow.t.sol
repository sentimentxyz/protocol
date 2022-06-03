// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract RepayFlowTest is TestBase {
    using PRBMathUD60x18 for uint;
    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testRepayEth(uint96 depositAmt, uint96 borrowAmt, uint96 repayAmt)
        public
    {
        // Setup
        cheats.assume(borrowAmt > repayAmt);
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
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
        cheats.assume(borrowAmt > repayAmt);
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
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
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
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
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
    }
    
    function testMaxRepayERC20WithInterest(uint96 depositAmt, uint96 borrowAmt)
        public
    {
        // Setup
        cheats.assume(borrowAmt > 0);
        cheats.assume(MAX_LEVERAGE.mul(depositAmt) > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);
        cheats.roll(block.number + 100);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(lErc20.getBorrowBalance(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }
}