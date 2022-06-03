// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import "forge-std/Test.sol";

contract AccountManagerDepositWithdrawTest is TestBase {
    using FixedPointMathLib for uint96;
    using FixedPointMathLib for uint256;
    address account;
    address public owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    // Deposit Eth
    function testDepositEthAuthError(uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.depositEth{value: value}(account);
    }

    // Withdraw Eth
    function testWithdrawEth(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(
            (depositAmt - withdrawAmt +
            (borrowAmt - borrowAmt.mulWadDown(borrowFee)))
            .divWadDown(borrowAmt) > balanceToBorrowThreshold
        ); // Ensure account is healthy after withdrawal// Ensure account is healthy after withdrawal
        deposit(owner, account, address(0), depositAmt);
        uint borrowAmtAfterFee =
            borrow(owner, account, address(weth), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.withdrawEth(account, withdrawAmt);

        // Assert
        assertEq(
            riskEngine.getBalance(account),
            uint(depositAmt) - uint(withdrawAmt) + borrowAmtAfterFee
        );
    }

    function testWithdrawEthRiskEngineError(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        cheats.assume(
            MAX_LEVERAGE.mulWadDown(depositAmt - withdrawAmt) <= borrowAmt
        ); // Ensures withdraw amt is large enough to breach the risk threshold
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(weth), borrowAmt);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.withdrawEth(account, withdrawAmt);
    }

    function testWithdrawEthAuthError(uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.withdrawEth(account, value);
    }

    // Deposit ERC20
    function testDepositAuthError(address token, uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.deposit(account, token, value);
    }

    function testDepositCollateralTypeError(address token, uint96 value)
        public
    {
        // Test
        cheats.assume(token != address(0) && !isContract(token));
        cheats.prank(owner);
        cheats.expectRevert(Errors.CollateralTypeRestricted.selector);
        accountManager.deposit(account, token, value);
    }

    // Withdraw ERC20
    function testWithdraw(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(
            (depositAmt - withdrawAmt +
            (borrowAmt - borrowAmt.mulWadDown(borrowFee)))
            .divWadDown(borrowAmt) > balanceToBorrowThreshold
        ); // Ensure account is healthy after withdrawal
        deposit(owner, account, address(erc20), depositAmt);
        uint borrowAmtAfterFee =
            borrow(owner, account, address(erc20), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.withdraw(account, address(erc20), withdrawAmt);

        // Assert
        assertEq(
            erc20.balanceOf(account),
            uint(depositAmt) - uint(withdrawAmt) + borrowAmtAfterFee
        );
    }

    function testWithdrawRiskEngineError(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(MAX_LEVERAGE.mulWadDown(depositAmt) > borrowAmt);
        cheats.assume(
            MAX_LEVERAGE.mulWadDown(depositAmt - withdrawAmt) <= borrowAmt
        ); // Ensures withdraw amt is large enough to breach the risk threshold
        deposit(owner, account, address(erc20), depositAmt);
        borrow(owner, account, address(erc20), borrowAmt);

        // Test
        cheats.prank(owner);
        cheats.expectRevert(Errors.RiskThresholdBreached.selector);
        accountManager.withdraw(account, address(erc20), withdrawAmt);
    }

    function testWithdrawAuthError(address token, uint96 value) public {
        // Test
        cheats.expectRevert(Errors.AccountOwnerOnly.selector);
        accountManager.withdraw(account, token, value);
    }
}