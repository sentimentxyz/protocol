// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestBase} from "../utils/TestBase.sol";

contract LendingFlowTest is TestBase {

    function setUp() public {
        setupContracts();
    }

    function testDepositEth(uint64 amt) public {
        // Setup
        cheats.assume(amt > 10 ** (18 - 2));
        cheats.deal(lender, amt);

        // Test
        cheats.prank(lender);
        lEth.depositEth{value: amt}();

        // Asserts
        assertEq(lender.balance, 0);
        assertEq(weth.balanceOf(address(lEth)), amt);
        assertGe(lEth.convertToAssets(lEth.balanceOf(lender)), amt);
    }

    function testWithdrawEth(uint64 amt) public {
        // Setup
        testDepositEth(amt);
        uint shares = lEth.balanceOf(lender);

        // Test
        cheats.prank(lender);
        lEth.redeemEth(shares);

        // Asserts
        assertEq(lender.balance, amt);
        assertEq(lEth.balanceOf(lender), 0);
        assertEq(address(lEth).balance, 0);
    }

    function testDepositERC20(uint64 amt) public {
        // Setup
        cheats.assume(amt > 10 ** (18 - 2));
        erc20.mint(lender, amt);

        // Test
        cheats.startPrank(lender);
        erc20.approve(address(lErc20), type(uint).max);
        lErc20.deposit(amt, lender);
        cheats.stopPrank();

        // Asserts
        assertEq(erc20.balanceOf(lender), 0);
        assertEq(erc20.balanceOf(address(lErc20)), amt);
        assertGe(lErc20.convertToAssets(lErc20.balanceOf(lender)), amt);
    }

    function testWithdrawERC20(uint64 amt) public {
        // Setup
        cheats.assume(amt > 10 ** (18 - 2));
        testDepositERC20(amt);
        uint shares = lErc20.balanceOf(lender);

        // Test
        cheats.prank(lender);
        lErc20.redeem(shares, lender, lender);

        // Asserts
        assertEq(erc20.balanceOf(lender), amt);
        assertEq(erc20.balanceOf(address(lErc20)), 0);
        assertEq(lErc20.balanceOf(lender), 0);

    }
}
