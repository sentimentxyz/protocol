// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {TestBase} from "../utils/TestBase.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract ReserveTests is TestBase {
    using FixedPointMathLib for uint;

    address public account;
    address lp = cheats.addr(100);
    address borrower = cheats.addr(101);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testReserves(uint96 deposit, uint96 borrow) public {
        cheats.assume(borrow > 0);
        cheats.assume(
            (uint(deposit) + borrow).divWadDown(borrow) >
            riskEngine.balanceToBorrowThreshold()
        );

        // LP deposits assets
        erc20.mint(lp, borrow);
        erc20.mint(borrower, deposit);
        cheats.startPrank(lp);
        erc20.approve(address(lErc20), borrow);
        uint shares = lErc20.deposit(borrow, lp);
        cheats.stopPrank();

        // Borrower borrows and max repays after 100 blocks
        cheats.startPrank(borrower);
        erc20.approve(address(accountManager), deposit);
        accountManager.deposit(account, address(erc20), deposit);
        accountManager.borrow(account, address(erc20), borrow);
        cheats.roll(block.number + 100);
        accountManager.repay(account, address(erc20), type(uint).max);
        cheats.stopPrank();

        // LP removes all liq
        cheats.prank(lp);
        lErc20.redeem(shares, lp, lp);

        assertEq(erc20.balanceOf(address(lErc20)), lErc20.getReserves());
    }

    function testReserves2(uint96 deposit, uint96 borrow) public {
        cheats.assume(borrow > 0);
        cheats.assume(
            (uint(deposit) + borrow).divWadDown(borrow) >
            riskEngine.balanceToBorrowThreshold()
        );

        // LP deposits assets
        erc20.mint(lp, borrow);
        erc20.mint(borrower, deposit);
        cheats.startPrank(lp);
        erc20.approve(address(lErc20), borrow);
        uint shares = lErc20.deposit(borrow, lp);
        cheats.stopPrank();

        // Borrower borrows and max repays after 100 blocks
        cheats.startPrank(borrower);
        erc20.approve(address(accountManager), deposit);
        accountManager.deposit(account, address(erc20), deposit);
        accountManager.borrow(account, address(erc20), borrow);
        cheats.roll(block.number + 100);
        accountManager.repay(account, address(erc20), type(uint).max);
        cheats.stopPrank();

        // Redeem Reserves
        lErc20.redeemReserves(lErc20.getReserves());

        // LP removes all liq
        cheats.prank(lp);
        lErc20.redeem(shares, lp, lp);

        // assertEq(erc20.balanceOf(address(lErc20)), lErc20.getReserves());
    }
}

