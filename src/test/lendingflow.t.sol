// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ds-test/src/test.sol";
import { ERC20PresetFixedSupply } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import "./Cheatcode.sol";

import "./Setup.sol";

contract LendingFlowTest is Test {

    function testLtokenCreation() public {
        string memory name = "sentiment";

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
}