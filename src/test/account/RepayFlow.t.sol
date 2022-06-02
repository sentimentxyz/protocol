// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract RepayFlowTest is TestBase {
    using FixedPointMathLib for uint96;
    using FixedPointMathLib for uint256;

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
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
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
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);
        erc20.mint(account, borrowAmt.mulWadDown(borrowFee));

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
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
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
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
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
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);
        erc20.mint(account, type(uint128).max);
        cheats.roll(block.number + 100);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), type(uint).max);

        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(lErc20.borrows(), 0);
    }

    function testRepayInParts(uint96 depositAmt, uint96 borrowAmt, uint96 repayAmt)
        public
    {
        // Setup
        cheats.assume(borrowAmt > repayAmt);
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        borrow(borrower, account, address(erc20), borrowAmt);
        erc20.mint(account, type(uint128).max);
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
}