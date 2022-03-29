// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

contract AccountManagerAdminOnlyTest is TestBase {
    function setUp() public {
        setupContracts();
    }

    function testInitialize() public {
        // Setup
        assertEq(address(registry), address(accountManager.registry()));

        // Test
        accountManager.initialize();

        // Assert
        assertEq(address(riskEngine), address(accountManager.riskEngine()));
        assertEq(address(controller), address(accountManager.controller()));
        assertEq(address(accountFactory), address(accountManager.accountFactory()));
    }

    function testInitializeAuthError(address caller) public {
        cheats.assume(!isContract(caller));
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.initialize();
    }
}