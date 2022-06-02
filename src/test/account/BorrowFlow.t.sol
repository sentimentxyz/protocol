// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract BorrowFlowTest is TestBase {
    using PRBMathUD60x18 for uint;
    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testBorrowEth(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt != 0);
        uint protocolFee = borrowFee.mul(borrowAmt);

        // Test
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        deposit(borrower, account, address(0), depositAmt);
        uint borrowAmtAfterFee =
            borrow(borrower, account, address(weth), borrowAmt);

        // Assert
        assertEq(address(lEth).balance, 0);
        assertEq(
            riskEngine.getBalance(account),
            uint(depositAmt) + borrowAmtAfterFee
        );
        assertTrue(!IAccount(account).hasNoDebt());
        assertEq(lEth.getBorrowBalance(address(account)), borrowAmt);
        assertEq(weth.balanceOf(treasury), protocolFee);
    }

    function testBorrowERC20(uint96 depositAmt, uint96 borrowAmt) public {
        cheats.assume(borrowAmt != 0);
        // Test
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        deposit(borrower, account, address(erc20), depositAmt);
        uint borrowAmtAfterFee =
            borrow(borrower, account, address(erc20), borrowAmt);

        // Assert
        assertTrue(!IAccount(account).hasNoDebt());
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(lErc20.getBorrowBalance(address(account)), borrowAmt);
        assertEq(
            erc20.balanceOf(address(account)),
            uint(depositAmt) + borrowAmtAfterFee
        );
    }

    function testBorrowERC20AfterExternalTransfer(
        uint96 depositAmt,
        uint96 borrowAmt,
        address sender,
        uint96 transferAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0 && sender != address(0));
        erc20.mint(sender, transferAmt);
        cheats.prank(sender);
        erc20.transfer(account, transferAmt);
        deposit(borrower, account, address(0), depositAmt);

        // Test
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);
        uint borrowAmtAfterFee =
            borrow(borrower, account, address(erc20), borrowAmt);

        // Assert
        assertTrue(!IAccount(account).hasNoDebt());
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(lErc20.getBorrowBalance(address(account)), borrowAmt);
        assertEq(
            erc20.balanceOf(address(account)),
            uint(transferAmt) + borrowAmtAfterFee
        );
        assertTrue(IAccount(account).hasAsset(address(erc20)));
        assertEq(address(erc20), IAccount(account).assets(0));
    }
}