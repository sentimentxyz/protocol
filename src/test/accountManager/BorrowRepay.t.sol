// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {console} from "../utils/console.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract AccountManagerBorrowRepayTest is TestBase {
    using FixedPointMathLib for uint;
    address account;
    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    function testBorrow(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt > 0);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(owner, account, address(erc20), depositAmt);
        erc20.mint(registry.LTokenFor(address(erc20)), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.borrow(account, address(erc20), borrowAmt);

        // Assert
        assertEq(erc20.balanceOf(account), uint(depositAmt) + uint(borrowAmt));
    }

    function testBorrowEth(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(borrowAmt > 10 ** (18 - 2));
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(owner, account, address(0), depositAmt);

        // Test
        borrow(owner, account, address(weth), borrowAmt);
        assertEq(riskEngine.getBalance(account), uint(depositAmt) + borrowAmt);
    }

    function testBorrowRiskEngineError(
        uint96 depositAmt,
        uint96 borrowAmt
    )
        public
    {
        // Setup
        cheats.assume(depositAmt != 0 && borrowAmt > 10 ** (18 - 2));
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) <=
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(owner, account, address(erc20), depositAmt);
        erc20.mint(registry.LTokenFor(address(erc20)), borrowAmt);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.borrow(account, address(erc20), borrowAmt);
    }

    function testBorrowEthRiskEngineError(
        uint96 depositAmt,
        uint96 borrowAmt
    )
        public
    {
        // Setup
        cheats.assume(depositAmt != 0 && borrowAmt > 10 ** (18 - 2));
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) <=
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(owner, account, address(0), depositAmt);
        cheats.deal(address(lEth), borrowAmt);
        cheats.prank(address(lEth));
        weth.deposit{value: borrowAmt}();

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.borrow(account, address(weth), borrowAmt);
    }

    function testBorrowAuthError(address token, uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.borrow(account, token, value);
    }

    function testBorrowLTokenUnavailableError(
        address token,
        uint96 value
    )
        public
    {
        // Setup
        cheats.assume(token != address(0) && !isContract(token));

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.LTokenUnavailable.selector);
        accountManager.borrow(account, token, value);
    }

    // Repay
    function testRepayAuthError(address token, uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.repay(account, token, value);
    }

    function testRepayLTokenUnavailableError(
        address token,
        uint96 value
    )
        public
    {
        // Setup
        cheats.assume(token != address(0) && !isContract(token));

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.LTokenUnavailable.selector);
        accountManager.repay(account, token, value);
    }
}