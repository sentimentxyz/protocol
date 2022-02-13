// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IUserRegistry} from "../interface/core/IUserRegistry.sol";

contract UserRegistry is Pausable, IUserRegistry {

    address public accountManager;
    mapping(address => address[]) accountListFor;
    mapping(address => address) public accountOwnerFor;

    event UpdateAccountManagerAddress(address indexed accountManager);

    constructor() Pausable(msg.sender) {}

    modifier accountManagerOnly() {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function addAccount(address account, address owner) external accountManagerOnly {
        accountOwnerFor[account] = owner;
        accountListFor[owner].push(account);
    }

    function closeAccount(address account, address owner) external accountManagerOnly {
        accountOwnerFor[account] = address(0);
        
        address[] storage accounts = accountListFor[owner];
        for(uint i = 0; i < accounts.length; ++i) {
            if(accounts[i] == account) {
                accounts[i] = accounts[accounts.length - 1];
                accounts.pop();
                break;
            }
        }
    }

    function accountsOwnedBy(address user) external view returns (address[] memory) {
        return accountListFor[user];
    }

    // Admin only
    function setAccountManagerAddress(address _accountManager) external adminOnly {
        accountManager = _accountManager;
        emit UpdateAccountManagerAddress(accountManager);
    }
}