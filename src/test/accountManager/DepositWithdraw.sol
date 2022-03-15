// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

contract AccountManagerDepositWithdrawTest is TestBase {
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
        uint96 withdrawAmt,
        uint96 borrowAmt
    ) 
        public 
    {
        // Setup
        cheats.assume(withdrawAmt != 0);
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(
            MAX_LEVERAGE * (depositAmt - withdrawAmt) > borrowAmt
        );
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(0), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.withdrawEth(account, withdrawAmt);

        // Assert
        assertEq(
            account.balance,
            uint(depositAmt) - uint(withdrawAmt) + uint(borrowAmt)
        );
    }

    function testWithdrawEthRiskEngineError(
        uint96 depositAmt,
        uint96 withdrawAmt,
        uint96 borrowAmt
    ) 
        public 
    {
        // Setup
        cheats.assume(withdrawAmt != 0);
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(MAX_LEVERAGE * depositAmt > borrowAmt);

        // Withdraw amount that breaks the above condition
        cheats.assume(
            (depositAmt - withdrawAmt) * MAX_LEVERAGE <= borrowAmt
        );
        deposit(owner, account, address(erc20), depositAmt);
        borrow(owner, account, address(erc20), borrowAmt);

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
        cheats.prank(owner);
        cheats.expectRevert(Errors.CollateralTypeRestricted.selector);
        accountManager.deposit(account, token, value);
    }

    // Withdraw ERC20
    function testWithdraw(
        uint96 depositAmt, 
        uint96 withdrawAmt, 
        uint96 borrowAmt
    ) 
        public 
    {
        // Setup
        cheats.assume(withdrawAmt != 0);
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(
            MAX_LEVERAGE * (depositAmt - withdrawAmt) > borrowAmt
        ); 
        deposit(owner, account, address(erc20), depositAmt);
        borrow(owner, account, address(erc20), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.withdraw(account, address(erc20), withdrawAmt);

        // Assert
        assertEq(
            erc20.balanceOf(account),
            uint(depositAmt) - uint(withdrawAmt) + uint(borrowAmt)
        );
    }

    function testWithdrawRiskEngineError(
        uint96 depositAmt,
        uint96 withdrawAmt,
        uint96 borrowAmt
    ) 
        public 
    {
        // Setup
        cheats.assume(
            borrowAmt != 0 && depositAmt != 0 &&
            withdrawAmt != 0 && depositAmt >= withdrawAmt
        );
        
        // Max Leverage is MAX_LEVERAGEx
        cheats.assume(depositAmt * MAX_LEVERAGE > borrowAmt); 
        
        // Withdraw amount that breaks the above condition
        cheats.assume(
            (depositAmt - withdrawAmt) * MAX_LEVERAGE <= borrowAmt
        ); 
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