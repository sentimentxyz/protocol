// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {TestERC20} from "../utils/TestERC20.sol";
import {console} from "../utils/console.sol";
import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract RiskEngineTest is TestBase {
    using FixedPointMathLib for uint;

    address account;
    address owner = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(owner);
    }

    function testIsBorrowAllowed(uint96 depositAmt, uint96 borrowAmt) public {
        // Setup
        cheats.assume(depositAmt != 0 && borrowAmt != 0);
        deposit(owner, account, address(0), depositAmt);

        // Test
        bool isBorrowAllowed = riskEngine.isBorrowAllowed(
            account,
            address(0),
            borrowAmt
        );

        // Assert
        (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold() ?
            assertTrue(isBorrowAllowed)
            : assertFalse(isBorrowAllowed);
    }

    function testIsWithdrawAllowed(
        uint96 depositAmt,
        uint96 borrowAmt,
        uint96 withdrawAmt
    )
        public
    {
        // Setup
        cheats.assume(borrowAmt != 0);
        cheats.assume(depositAmt > withdrawAmt);
        cheats.assume(
            (uint(depositAmt) + borrowAmt).divWadDown(borrowAmt) >
            riskEngine.balanceToBorrowThreshold()
        );
        deposit(owner, account, address(0), depositAmt);
        borrow(owner, account, address(weth), borrowAmt);

        // Test
        bool isWithdrawAllowed = riskEngine.isWithdrawAllowed(
            account,
            address(0),
            withdrawAmt
        );

        // Assert
        (uint(depositAmt) + borrowAmt - withdrawAmt).divWadDown(borrowAmt) >
        riskEngine.balanceToBorrowThreshold() ?
        assertTrue(isWithdrawAllowed) : assertFalse(isWithdrawAllowed);
    }

    function testInitialize() public {
        // Setup
        assertEq(address(registry), address(riskEngine.registry()));

        // Test
        riskEngine.initDep();

        // Assert
        assertEq(address(oracle), address(riskEngine.oracle()));
        assertEq(address(accountManager), address(riskEngine.accountManager()));
    }

    function testInitializeAuthError(address caller) public {
        cheats.assume(caller != riskEngine.admin());
        cheats.prank(caller);
        cheats.expectRevert(Errors.AdminOnly.selector);
        riskEngine.initDep();
    }

    function testGetAccountBalance(uint8 decimals) public {
        // Setup
        cheats.assume(decimals <= 18 && decimals > 0);

        TestERC20 testERC20 = new TestERC20("TestERC20", "TEST", decimals);
        accountManager.toggleCollateralStatus(address(testERC20));

        deposit(owner, account, address(0), 1 ether);
        deposit(owner, account, address(testERC20), 1000 * 10 ** decimals);

        // Test
        uint bal = riskEngine.getBalance(account);

        // Assert
        assertEq(bal, 1001e18);
    }
}