// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";

contract AccountManagerAdminOnlyTest is TestBase {
    function setUp() public {
        setupContracts();
    }

    function testToggleCollateralState(address token) public {
        // Test
        accountManager.toggleCollateralState(token);

        // Assert
        assertTrue(accountManager.isCollateralAllowed(token));
    }

    function testToggleCollateralStateAuthError(
        address caller,
        address token
    )
        public
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.toggleCollateralState(token);

        // Assert
        assertFalse(accountManager.isCollateralAllowed(token));
    }

    function testSetLToken(address token, address LToken) public {
        // Test
        accountManager.setLTokenAddress(token, LToken);

        // Assert
        assertEq(accountManager.LTokenAddressFor(token), LToken);
    }

    function testSetLTokenAuthError(
        address caller,
        address token,
        address LToken
    )
        public
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.setLTokenAddress(token, LToken);

        // Assert
        assertEq(accountManager.LTokenAddressFor(token), address(0));
    }

    function testSetRiskEngine(address _riskEngine) public {
        // Test
        accountManager.setRiskEngineAddress(_riskEngine);

        // Assert
        assertEq(address(accountManager.riskEngine()), _riskEngine);
    }

    function testSetRiskEngineAuthError(
        address caller,
        address _riskEngine
    ) 
        public 
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.setRiskEngineAddress(_riskEngine);
    }

    function testSetUserRegistryAddress(address _registry) public {
        // Test
        accountManager.setUserRegistryAddress(_registry);

        // Assert
        assertEq(address(accountManager.registry()), _registry);
    }

    function testSetUserRegistryAuthError(
        address caller,
        address _userRegistry
    ) 
        public 
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.setUserRegistryAddress(_userRegistry);
    }

    function testSetController(address controller) public {
        // Test
        accountManager.setControllerAddress(controller);

        // Assert
        assertEq(address(accountManager.controller()), controller);
    }

    function testSetControllerAuthError(
        address caller,
        address controller
    ) 
        public 
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.setControllerAddress(controller);
    }

    function testSetAccountFactory(address _accountFactory) public {
        // Test
        accountManager.setAccountFactoryAddress(_accountFactory);

        // Assert
        assertEq(address(accountManager.accountFactory()), _accountFactory);
    }

    function testSetAccountFactoryAuthError(
        address caller,
        address _accountFactory
    ) 
        public 
    {
        // Test
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        accountManager.setAccountFactoryAddress(_accountFactory);
    }
}