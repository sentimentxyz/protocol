// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract LendingFlowTest is TestBase {
    using PRBMathUD60x18 for uint;

    address lender = cheats.addr(1);

    function setUp() public {
        setupContracts();
    }

    function testDepositEth(uint amt) public {
        // Setup
        cheats.deal(lender, amt);

        // Test
        cheats.prank(lender);
        lEth.depositEth{value: amt}();

        // Asserts
        assertEq(lender.balance, 0);
        assertEq(address(lEth).balance, amt);
        assertGe(lEth.convertToAssets(lEth.balanceOf(lender)), amt);
    }

    function testWithdrawEth(uint amt) public {
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

    function testDepositERC20(uint amt) public {
        // Setup
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

    function testWithdrawERC20(uint amt) public {
        // Setup
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
