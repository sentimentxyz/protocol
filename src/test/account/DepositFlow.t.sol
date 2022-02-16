pragma solidity ^0.8.10;

import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";

contract DepositFlow is TestBase {
    address public account;
    address public borrower = cheats.addr(1);

    function setUp() public {
        setupContracts();
        account = openAccount(borrower);
    }

    function testDepositCollateralETH(uint96 amt) public {
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
}