// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ds-test/src/test.sol";

import "./Cheatcode.sol";

import "./Setup.sol";

contract LendingFlowTest is Test {

    address public user1;
    address public creator;

    function setUp() public {
        user1 = cheatCode.addr(2);
        creator = cheatCode.addr(1);
        cheatCode.startPrank(creator);
        basicSetup();
        token.mint(user1, 100);
        cheatCode.stopPrank();
    }

    function testLtokenCreation() public {
        string memory name = "LSentiment";

        assertEq(keccak256(abi.encodePacked((ltoken.name()))), keccak256(abi.encodePacked((name))));
        assertEq(token.balanceOf(user1), 100);
        assertEq(ltoken.underlyingAddr(), address(token));
    }

    function testDeposit() public {
        cheatCode.startPrank(user1);
        token.approve(address(ltoken), type(uint).max);
        ltoken.deposit(10);
        assertEq(token.balanceOf(user1), 90);
        assertEq(token.balanceOf(address(ltoken)), 10);
        assertEq(ltoken.balanceOf(user1), 10);
    }

    function testWithdraw() public {
        cheatCode.startPrank(user1);
        token.approve(address(ltoken), type(uint).max);
        ltoken.deposit(10);
        ltoken.withdraw(10);
        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(address(ltoken)), 0);
        assertEq(ltoken.balanceOf(user1), 0);
    }

    function testDepositEth() public {
        cheatCode.deal(user1, 100);
        cheatCode.startPrank(user1);
        lEther.deposit{value: 10}();
        assertEq(address(lEther).balance, 10);
        assertEq(lEther.balanceOf(user1), 10);
        assertEq(user1.balance, 90);
    }

    function testWithdrawEth() public {
        address user3 = cheatCode.addr(10);
        cheatCode.deal(user3, 10);
        cheatCode.startPrank(user3);
        lEther.deposit{value: 10}();
        lEther.withdraw(10);
        assertEq(user3.balance, 10);
        assertEq(address(lEther).balance, 0);
        assertEq(lEther.balanceOf(user3), 0);
    }
}