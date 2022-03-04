// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IUserRegistry} from "../interface/core/IUserRegistry.sol";

contract UserRegistry is Pausable, IUserRegistry {

    address public accountManager;
    address[] public accounts;
    mapping(address => address) public ownerFor;

    constructor() Pausable(msg.sender) {}

    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function getAllAccounts() external view returns (address[] memory) {
        return accounts;
    }

    function updateAccount(address account, address owner)
        external
        accountManagerOnly 
    {
        ownerFor[account] = owner;
    }

    function addAccount(address account, address owner)
        external
        accountManagerOnly 
    {
        ownerFor[account] = owner;
        accounts.push(account);
    }

    function closeAccount(address account) external accountManagerOnly {
        ownerFor[account] = address(0);
    }

    function accountsOwnedBy(address user)
        external
        view
        returns (address[] memory) 
    {
        address[] memory userAccounts = new address[](accounts.length);
        uint index = 0;
        for (uint i = 0; i < accounts.length; i++) {
            if (ownerFor[accounts[i]] == user) {
                userAccounts[index] = accounts[i];
                index++;
            }
        }

        if (index == 0) return new address[](0);
        return userAccounts;
    }

    // Admin only
    function setAccountManagerAddress(address _accountManager)
        external
        adminOnly
    {
        accountManager = _accountManager;
        emit UpdateAccountManagerAddress(accountManager);
    }
}