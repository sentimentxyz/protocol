// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TestBase} from "./utils/TestBase.sol";
import {IAccount} from "../interface/core/IAccount.sol";

contract RepayingFlowTest is TestBase {
    
    address public user = cheats.addr(1);

    function setUp() public {
        setupContracts();
    }

    function testRepayEth(uint96 amt) public {
        // Setup
        cheats.prank(user);
        IAccount account = IAccount(openAccount(user));
        deposit(user, address(account), address(0), amt);
        borrow(user, address(account), address(0), amt);

        // Test
        cheats.prank(user);
        accountManager.repay(address(account), address(0), amt);

        // Assert
        assertEq(riskEngine.getBalance(address(account)), amt);
        assertEq(riskEngine.getBorrows(address(account)), 0);
    }

    function testRepayERC20(uint96 amt) public {
        // Setup
        cheats.prank(user);
        IAccount account = IAccount(openAccount(user));
        deposit(user, address(account), address(erc20), amt);
        borrow(user, address(account), address(erc20), amt);

        // Test
        cheats.prank(user);
        accountManager.repay(address(account), address(erc20), amt);

        // Assert
        assertEq(riskEngine.getBalance(address(account)), amt);
        assertEq(riskEngine.getBorrows(address(account)), 0);
    }
}