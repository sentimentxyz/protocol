// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract AccountManagerDepositWithdrawTest is TestBase {
    using FixedPointMathLib for uint;
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
            (uint(depositAmt) + borrowAmt - withdrawAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        ); // Ensure account is healthy after withdrawal
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(weth), borrowAmt);

        // Test
        cheats.prank(owner);
        accountManager.withdrawEth(account, withdrawAmt);

        // Assert
        assertEq(
            riskEngine.getBalance(account),
            uint(depositAmt) - uint(withdrawAmt) + uint(borrowAmt)
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
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        cheats.assume(
            (uint(depositAmt) + borrowAmt - withdrawAmt).divWadDown(borrowAmt) <=
            riskEngine.balanceToBorrowThreshold()
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
            (uint(depositAmt) + borrowAmt - withdrawAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        ); // Ensure account is healthy after withdrawal
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
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt >= withdrawAmt);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        cheats.assume(
            (uint(depositAmt) + borrowAmt - withdrawAmt).divWadDown(borrowAmt) <=
            riskEngine.balanceToBorrowThreshold()
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