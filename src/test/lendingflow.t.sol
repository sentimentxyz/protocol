// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ds-test/src/test.sol";
import { ERC20PresetFixedSupply } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import "./Cheatcode.sol";

import "./Setup.sol";

contract LendingFlowTest is Test {

    function testLtokenCreation() view public {
        string memory name = "sentiment";
        require(keccak256(abi.encodePacked((ltoken.name()))) == keccak256(abi.encodePacked((name))));
        require(token.balanceOf(user1) == 100);
        require(ltoken.underlyingAddr() == address(token));
    }

    function testDeposit() public {
        cheatCode.startPrank(user1);
        token.approve(address(ltoken), type(uint).max);
        ltoken.deposit(10);
        require(token.balanceOf(user1) == 90);
        require(token.balanceOf(address(ltoken)) == 10);
        require(ltoken.balanceOf(user1) == 10);
    }
}