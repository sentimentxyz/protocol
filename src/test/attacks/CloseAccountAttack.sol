// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Errors} from "../../utils/Errors.sol";
import {TestBase} from "../utils/TestBase.sol";
import {IAccount} from "../../interface/core/IAccount.sol";
import {IAccountManager} from "../../interface/core/IAccountManager.sol";

contract CloseAccountAttacker {

    IAccountManager accountManager;

    constructor(IAccountManager _accountManager) {
        accountManager = _accountManager;
    }

    fallback() external payable {
        _attack();
    }

    receive() external payable {
        _attack();
    }

    function _attack() internal {
        accountManager.closeAccount(msg.sender);
    }
}

contract CloseAccountAttack is TestBase {

    IAccount public account;
    CloseAccountAttacker owner;

    function setUp() public {
        setupContracts();
        owner = new CloseAccountAttacker(accountManager);
        account = IAccount(openAccount(address(owner)));
    }

    function testAccountCloseAttack() public {
        cheats.roll(block.number + 1);
        cheats.prank(address(owner));
        cheats.expectRevert(Errors.EthTransferFailure.selector);
        accountManager.closeAccount(address(account));
    }
}