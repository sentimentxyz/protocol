// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract RepayFlowTest is TestBase {
    using PRBMathUD60x18 for uint96;
    using PRBMathUD60x18 for uint256;

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
        cheats.assume(MAX_LEVERAGE.mul(depositAmt) > borrowAmt);
        deposit(borrower, account, address(0), depositAmt);
        borrow(borrower, account, address(weth), borrowAmt);
        mintWETH(account, borrowAmt);

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
        cheats.assume(MAX_LEVERAGE.mul(depositAmt) > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);
        erc20.mint(account, borrowAmt.mul(borrowFee));

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
        cheats.assume(MAX_LEVERAGE.mul(depositAmt) > borrowAmt);
        deposit(borrower, account, address(0), depositAmt);
        borrow(borrower, account, address(weth), borrowAmt);
        mintWETH(account, borrowAmt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(weth), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
    }

    function testMaxRepayERC20(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt > 0);
        cheats.assume(MAX_LEVERAGE.mul(depositAmt) > borrowAmt);
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

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.borrows(), 0);
    }

    function testRepayInParts() public
    {
        uint depositAmt = 20e18;
        uint borrowAmt = 40e18;
        deposit(borrower, account, address(erc20), depositAmt);
        // console.log("A1", lErc20.getBorrows(), lErc20.getBorrowBalance(account));
        borrow(borrower, account, address(erc20), borrowAmt);
        // console.log("A2", lErc20.getBorrows(), lErc20.getBorrowBalance(account));
        cheats.roll(block.number + 100);
        // console.log("A3", lErc20.getBorrows(), lErc20.getBorrowBalance(account));

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), 20e18);
        // console.log("A4", lErc20.getBorrows(), lErc20.getBorrowBalance(account));

        // console.log("B1", lErc20.borrowsOf(account), lErc20.totalAssets(), lErc20.totalSupply());
        cheats.roll(block.number + 100);
        // console.log("B2", lErc20.borrowsOf(account), lErc20.totalAssets(), lErc20.totalSupply());
        // console.log("A5", lErc20.getBorrows(), lErc20.getBorrowBalance(account));

        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);
        // console.log("A6", lErc20.getBorrows(), lErc20.getBorrowBalance(account));

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.getBorrows(), 0);
    }
}