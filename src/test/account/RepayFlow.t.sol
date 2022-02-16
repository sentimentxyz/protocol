// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract RepayFlowTest is TestBase {
    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testRepayEth(uint96 amt) public {
        // Setup
        deposit(borrower, account, address(0), amt);
        borrow(borrower, account, address(0), amt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(0), amt);

        // Assert
        assertEq(riskEngine.getBalance(account), amt);
        assertEq(riskEngine.getBorrows(account), 0);
    }

    function testRepayERC20(uint96 amt) public {
        // Setup
        deposit(borrower, account, address(erc20), amt);
        borrow(borrower, account, address(erc20), amt);

        // Test
        cheats.prank(borrower);
        accountManager.repay(account, address(erc20), amt);

        // Assert
        assertEq(riskEngine.getBalance(account), amt);
        assertEq(riskEngine.getBorrows(account), 0);
    }
}