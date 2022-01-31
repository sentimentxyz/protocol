// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Errors.sol";

contract UserRegistry {

    address public admin;
    address public accountManager;

    struct User {
        address owner; // TODO do we really need this? Consider refactoring to address => address[]
        address[] marginAccounts;
    }
    
    mapping(address => User) public ownerUserMapping;

    event UpdateAdminAddress(address indexed admin);
    event UpdateAccountManagerAddress(address indexed accountManager);
    event AddMarginAccount(address indexed owner, address indexed marginAccount);
    event RemoveMarginAccount(address indexed owner, address indexed marginAccount);

    constructor() {
        admin = msg.sender;
    }

    modifier adminOnly() {
        if(msg.sender != admin) revert Errors.AdminOnly();
        _;
    }

    modifier accountManagerOnly() {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function updateAdminAddress(address _admin) public adminOnly {
        admin = _admin;
        emit UpdateAdminAddress(admin);
    }

    function setAccountManagerAddress(address _accountManager) public adminOnly {
        accountManager = _accountManager;
        emit UpdateAccountManagerAddress(accountManager);
    }

    function getMarginAccounts(address _owner) public view returns (address[] memory) {
        if(ownerUserMapping[_owner].owner == address(0)) revert Errors.AccountNotFound();
        return ownerUserMapping[_owner].marginAccounts;
    }

    function addMarginAccount(address _owner, address _marginAccount) public accountManagerOnly {
        if (ownerUserMapping[_owner].owner == address(0)) {
            ownerUserMapping[_owner] = User(_owner, new address[](1));
            ownerUserMapping[_owner].marginAccounts[0] = _marginAccount;
        } else {
            ownerUserMapping[_owner].marginAccounts.push(_marginAccount);
        }
        emit AddMarginAccount(_owner, _marginAccount);
    }

    function removeMarginAccount(address _owner, address _marginAccount) public accountManagerOnly {
        if(ownerUserMapping[_owner].owner == address(0)) revert Errors.AccountNotFound();
        address[] storage accounts = ownerUserMapping[_owner].marginAccounts;
        for(uint i=0; i < accounts.length; i++) {
            if (accounts[i] == _marginAccount) {
                accounts[i] = accounts[accounts.length-1];
                accounts.pop();
                break;
            }
        }
        emit RemoveMarginAccount(_owner, _marginAccount);
    }

}