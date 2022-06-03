// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IControllerFacade} from "controller/core/IControllerFacade.sol";

contract AccountManagerTest is TestBase {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for uint96;
    address account;
    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

     // Approve
    function testApproveAuthError(
        address spender,
        address token,
        uint96 value
    )
        public
    {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.approve(account, token, spender, value);
    }

    // Liquidate
    function testLiquidateHealthyAccount(
        uint96 depositAmt,
        uint borrowAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(weth), borrowAmt);

        // Test
        cheats.expectRevert(Errors.AccountNotLiquidatable.selector);
        accountManager.liquidate(account);
    }

    // Settle
    function testSettle(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        deposit(owner, account, address(0), depositAmt);
        deposit(owner, account, address(erc20), depositAmt);
        borrow(owner, account, address(weth), borrowAmt);
        borrow(owner, account, address(erc20), borrowAmt);
        erc20.mint(account, borrowAmt.mulWadDown(borrowFee));
        mintWETH(account, borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.settle(account);

        // Assert
        assertEq(account.balance, depositAmt);
        assertEq(erc20.balanceOf(account), depositAmt);
        assertEq(weth.balanceOf(address(lEth)), borrowAmt);
        assertEq(erc20.balanceOf(address(lErc20)), borrowAmt);
    }

    function testSettleAuthError() public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.settle(account);
    }
}