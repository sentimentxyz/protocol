pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract OpenCloseFlowTest is TestBase {
    address public account;
    address public user = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(user);
    }

    function testOpen() public {
        // Assert
        assertTrue(IAccount(account).hasNoDebt());
        assertEq(riskEngine.getBalance(account), 0);
        assertEq(riskEngine.getBorrows(account), 0);
        assertTrue(riskEngine.isAccountHealthy(account));
        assertEq(account, userRegistry.accountsOwnedBy(user)[0]);
        assertEq(address(accountManager), IAccount(account).accountManager());
    }

    function testFailCloseInSameBlock() public {
        // Test
        cheats.prank(user);
        accountManager.closeAccount(account);
    }

    function testClose() public {
        // Setup
        cheats.roll(block.number + 1);

        // Test
        cheats.prank(user);
        accountManager.closeAccount(account);

        // Assert
        assertTrue(userRegistry.accountsOwnedBy(user).length == 0);
        assertEq(address(accountManager), IAccount(account).accountManager());
    }

    function testReassign() public {
        // Setup
        testClose();

        // Test
        address account2 = openAccount(user);

        // Assert
        assertEq(account, account2);
        assertEq(account, userRegistry.accountsOwnedBy(user)[0]);
        assertEq(address(accountManager), IAccount(account).accountManager());
    }
}