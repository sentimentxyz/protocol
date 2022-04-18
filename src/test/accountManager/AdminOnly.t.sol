// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {console} from "../utils/console.sol";
import {IOwnable} from "../../interface/utils/IOwnable.sol";

contract AccountManagerAdminOnlyTest is TestBase {
    function setUp() public {
        setupContracts();
    }

    function testInitialize() public {
        // Setup
        assertEq(address(registry), address(accountManager.registry()));

        // Test
        accountManager.initDep();

        // Assert
        assertEq(address(riskEngine), address(accountManager.riskEngine()));
        assertEq(address(controller), address(accountManager.controller()));
        assertEq(address(accountFactory), address(accountManager.accountFactory()));
    }

    function testInitializeAuthError(address caller) public {
        cheats.assume(caller != IOwnable(address(accountManager)).admin());
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.initDep();
    }
}