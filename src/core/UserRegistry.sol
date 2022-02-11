// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Pausable} from "../utils/Pausable.sol";
import {IUserRegistry} from "../interface/core/IUserRegistry.sol";

contract UserRegistry is Pausable, IUserRegistry {

    address public accountManager;

    address[] public marginAccounts;
    mapping(address => address) public accountOwnerMapping;

    event UpdateAccountManagerAddress(address indexed accountManager);
    event UpdateMarginAccountOwner(address indexed marginAccount, address indexed owner);

    constructor() Pausable(msg.sender) {}

    modifier accountManagerOnly() {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function addMarginAccount(address _marginAccount) public accountManagerOnly {
        marginAccounts.push(_marginAccount);
    }

    function getMarginAccounts() public view returns (address[] memory) {
        return marginAccounts;
    }

    function setMarginAccountOwner(address _owner, address _marginAccount) public accountManagerOnly {
        accountOwnerMapping[_marginAccount] = _owner;
        emit UpdateMarginAccountOwner(_marginAccount, _owner);
    }

    function isValidOwner(address _owner, address _account) public view returns (bool) {
        return accountOwnerMapping[_account] == _owner;
    }

    // admin only
    function setAccountManagerAddress(address _accountManager) public adminOnly {
        accountManager = _accountManager;
        emit UpdateAccountManagerAddress(accountManager);
    }
}