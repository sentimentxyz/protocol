// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract UserRegistry {

    address public admin;
    address public accountManager;

    struct User {
        address owner;
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
        require(msg.sender == admin, "Registry/AdminOnly");
        _;
    }

    modifier accountManagerOnly() {
        require(msg.sender == accountManager, "Registry/AccountManagerOnly");
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
        require(ownerUserMapping[_owner].owner != address(0), "Registry/GetAccounts: Not found");
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
        require(ownerUserMapping[_owner].owner != address(0), "Registry/RemAccount: Not found");
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