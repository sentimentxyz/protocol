// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract DepositFlow is TestBase {
    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testDepositCollateralEth(uint96 amt) public {
        // Test
        deposit(borrower, account, address(0), amt);

        // Assert
        assertEq(borrower.balance, 0);
        assertEq(address(account).balance, amt);
        assertEq(riskEngine.getBalance(address(account)), amt);
        assertTrue(IAccount(account).hasNoDebt());
    }

    function testDepositCollateralERC20(uint96 amt) public {
        // Test
        deposit(borrower, account, address(erc20), amt);

        // Assert
        assertEq(erc20.balanceOf(borrower), 0);
        assertEq(erc20.balanceOf(address(account)), amt);
        assertEq(riskEngine.getBalance(address(account)), amt); // 1 ERC20 = 1 ETH
        assertTrue(IAccount(account).hasNoDebt());
    }

    function testDepositCollateralERC20AfterExternalTransfer(
        uint96 amt,
        address sender,
        uint96 transferAmt
    )
        public
    {
        // Setup
        cheats.assume(sender != address(0));
        erc20.mint(sender, transferAmt);
        cheats.prank(sender);
        erc20.transfer(account, transferAmt);


        // Test
        deposit(borrower, account, address(erc20), amt);

        // Assert
        assertEq(erc20.balanceOf(borrower), 0);
        assertEq(
            erc20.balanceOf(address(account)),
            uint(amt) + uint(transferAmt)
        );
        assertEq(
            riskEngine.getBalance(address(account)),
            uint(amt) + uint(transferAmt)
        ); // 1 ERC20 = 1 ETH
        assertTrue(IAccount(account).hasNoDebt());
        assertTrue(IAccount(account).hasAsset(address(erc20)));
        assertEq(address(erc20), IAccount(account).assets(0));
    }
}