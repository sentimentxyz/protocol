// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IUserRegistry} from "../interface/core/IUserRegistry.sol";

contract UserRegistry is Pausable, IUserRegistry {

    address public accountManager;

    address[] public accounts;
    mapping(address => uint) public ownerAccountCount;

    event UpdateAccountManagerAddress(address indexed accountManager);

    constructor() Pausable(msg.sender) {}

    modifier accountManagerOnly() {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function addAccount(address account) external accountManagerOnly {
        accounts.push(account);
        ownerAccountCount[address(0)]++;
    }

    function updateRegistry(address prevOwner, address newOwner) external accountManagerOnly {
        ownerAccountCount[prevOwner]--;
        ownerAccountCount[newOwner]++;
    }

    function getAccountsFor(address user) external view returns (address[] memory) {
        address[] memory result = new address[](ownerAccountCount[user]);
        uint counter = 0;
        for(uint i = 0; i < accounts.length; ++i) {
            if(IAccount(accounts[i]).owner() == user) result[counter++] = accounts[i];
        }
        return result;
    }

    // Admin only
    function setAccountManagerAddress(address _accountManager) external adminOnly {
        accountManager = _accountManager;
        emit UpdateAccountManagerAddress(accountManager);
    }
}