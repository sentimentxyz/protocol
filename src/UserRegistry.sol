// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Base.sol";
import "./utils/Errors.sol";
import "./utils/Pausable.sol";
import "./utils/ContractNames.sol";

contract UserRegistry is Pausable, Base {

    mapping(address => address) public accountOwnerMapping;
    mapping(address => address[]) public ownerAccountsMapping;

    event AddMarginAccount(address indexed owner, address indexed marginAccount);
    event RemoveMarginAccount(address indexed owner, address indexed marginAccount);

    constructor(address _addressProvider) {
        admin = msg.sender;
        addressProvider = IAddressProvider(_addressProvider);
    }

    modifier accountManagerOnly() {
        if(
            msg.sender != getAddress(ContractNames.AccountManager)
        ) revert Errors.AccountManagerOnly();
        _;
    }

    function getMarginAccounts(address _owner) public view returns (address[] memory) {
        return ownerAccountsMapping[_owner];
    }

    function addMarginAccount(address _owner, address _marginAccount) public accountManagerOnly {
        ownerAccountsMapping[_owner].push(_marginAccount);
        accountOwnerMapping[_marginAccount] = _owner;
        emit AddMarginAccount(_owner, _marginAccount);
    }

    function removeMarginAccount(address _owner, address _marginAccount) public accountManagerOnly {
        if(ownerAccountsMapping[_owner].length == 0) revert Errors.AccountsNotFound();
        address[] storage accounts = ownerAccountsMapping[_owner];
        for(uint i=0; i < accounts.length; i++) {
            if (accounts[i] == _marginAccount) {
                accounts[i] = accounts[accounts.length-1];
                accounts.pop();
                break;
            }
        }
        accountOwnerMapping[_marginAccount] = address(0);
        emit RemoveMarginAccount(_owner, _marginAccount);
    }

    function isValidOwner(address _owner, address _account) public view returns (bool) {
        return accountOwnerMapping[_account] == _owner;
    }
}