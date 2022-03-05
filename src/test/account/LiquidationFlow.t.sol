// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract LiquidationFlowTest is TestBase {
    address public borrower = cheats.addr(1);
    address public maintainer = cheats.addr(2);
    address public account;

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    // Mock RiskEngine call to allow liquidation
    function mockAccountRiskFactor() private {
        assertTrue(riskEngine.isAccountHealthy(account)); // Account is healthy pre-test
        cheats.mockCall(
            address(riskEngine), 
            abi.encodeWithSelector(riskEngine.isAccountHealthy.selector),
            abi.encode(false)
        );
        assertTrue(!riskEngine.isAccountHealthy(account)); // Account is now liquidatable
    }

    function testLiquidationEth(uint96 amt) public {
        // Setup
        deposit(borrower, account, address(0), amt);
        borrow(borrower, account, address(0), amt);
        mockAccountRiskFactor();
        cheats.deal(maintainer, amt);

        // Test
        cheats.prank(maintainer);
        accountManager.liquidate(account);

        // Assert
        assertEq(account.balance, 0);
        assertTrue(IAccount(account).hasNoDebt());
        assertEq(riskEngine.getBalance(account), 0);
        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(maintainer.balance, uint(2) * amt);
    }

    function testLiquidationERC20(uint96 amt) public {
        // Setup
        deposit(borrower, account, address(erc20), amt);
        borrow(borrower, account, address(erc20), amt);
        mockAccountRiskFactor();
        erc20.mint(maintainer, amt);

        // Test
        cheats.startPrank(maintainer);
        erc20.approve(address(accountManager), type(uint).max);
        accountManager.liquidate(account);
        cheats.stopPrank();

        // Assert
        assertEq(erc20.balanceOf(account), 0);
        assertTrue(IAccount(account).hasNoDebt());
        assertEq(riskEngine.getBalance(account), 0);
        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(erc20.balanceOf(maintainer), uint(2) * amt);
    }

    function testLiquidationComposite(uint96 amt) public {
        // Setup
        deposit(borrower, account, address(0), amt);
        borrow(borrower, account, address(0), amt);
        deposit(borrower, account, address(erc20), amt);
        borrow(borrower, account, address(erc20), amt);
        mockAccountRiskFactor();
        cheats.deal(maintainer, amt);
        erc20.mint(maintainer, amt);

        // Test
        cheats.startPrank(maintainer);
        erc20.approve(address(accountManager), type(uint).max);
        accountManager.liquidate(account);
        cheats.stopPrank();

        // Assert
        assertEq(account.balance, 0);
        assertEq(erc20.balanceOf(account), 0);
        assertTrue(IAccount(account).hasNoDebt());
        assertEq(riskEngine.getBalance(account), 0);
        assertEq(riskEngine.getBorrows(account), 0);
        assertEq(maintainer.balance, uint(2) * amt);
        assertEq(erc20.balanceOf(maintainer), uint(2) * amt);
    }
}