// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

contract Registry is Ownable, IRegistry {
    bytes32 private constant ORACLE = 'ORACLE';
    bytes32 private constant CONTROLLER = 'CONTROLLER';
    bytes32 private constant RATE_MODEL = 'RATE_MODEL';
    bytes32 private constant RISK_ENGINE = 'RISK_ENGINE';
    bytes32 private constant ACCOUNT_FACTORY = 'ACCOUNT_FACTORY';
    bytes32 private constant ACCOUNT_MANAGER = 'ACCOUNT_MANAGER';

    address[] public accounts;
    address[] public LTokenList;

    mapping(address => address) public ownerFor;
    mapping(address => address) public LTokenFor;
    mapping(bytes32 => address) public addressFor;

    constructor() Ownable(msg.sender) {}

    modifier accountManagerOnly() {
        if (msg.sender != addressFor['ACCOUNT_MANAGER']) 
            revert Errors.AccountManagerOnly();
        _;
    }
    
    // Account Registry Functions

    function setAddress(bytes32 id, address _address) external adminOnly {
        addressFor[id] = _address;
    }

    function addLToken(address underlying, address lToken) external adminOnly {
        LTokenList.push(lToken);
        LTokenFor[underlying] = lToken;
    }

    function updateLToken(address underlying, address lToken) 
        external
        adminOnly
    {
        if(lToken == address(0)) removeFromLTokenList(LTokenFor[underlying]);
        LTokenFor[underlying] = lToken;
    }

    function removeFromLTokenList(address token) internal {
        uint len = LTokenList.length;
        // Copy the last element in place of token and pop
        for(uint i; i < len;) {
            if (LTokenList[i] == token) {
                LTokenList[i] = LTokenList[len - 1];
                LTokenList.pop();
                break;
            }
            unchecked { ++i; }
        }
    }

    // User Registry Functions

    function addAccount(address account, address owner)
        external
        accountManagerOnly 
    {
        ownerFor[account] = owner;
        accounts.push(account);
        emit AccountCreated(account, owner);
    }

    function updateAccount(address account, address owner)
        external
        accountManagerOnly 
    {
        ownerFor[account] = owner;
    }

    function closeAccount(address account) external accountManagerOnly {
        ownerFor[account] = address(0);
    }

    // View Functions

    function getAllAccounts() external view returns (address[] memory) {
        return accounts;
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

        if (index == 0) return new address[](0); // TODO why is this required?
        return userAccounts;
    }
}