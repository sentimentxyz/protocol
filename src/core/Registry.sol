// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

contract Registry is Ownable, IRegistry {

    string[] public keys;
    address[] public accounts;
    address[] public LTokenList;

    mapping(address => address) public ownerFor;
    mapping(address => address) public LTokenFor;
    mapping(string => address) public addressFor;

    constructor() Ownable(msg.sender) {}

    modifier accountManagerOnly() {
        if (msg.sender != addressFor['ACCOUNT_MANAGER']) 
            revert Errors.AccountManagerOnly();
        _;
    }

    function setAddress(string calldata id, address _address) 
        external 
        adminOnly 
    {
        if (addressFor[id] == address(0)) {
            if (_address == address(0)) revert Errors.ZeroAddress();
            keys.push(id);
        }
        else if (_address == address(0)) removeKey(id);

        addressFor[id] = _address;
    }

    function setLToken(address underlying, address lToken) external adminOnly {
        if (LTokenFor[underlying] == address(0)) {
            if (lToken == address(0)) revert Errors.ZeroAddress();
            LTokenList.push(lToken);
        }
        else if (lToken == address(0)) removeLToken(LTokenFor[underlying]);
        else updateLToken(LTokenFor[underlying], lToken);

        LTokenFor[underlying] = lToken;
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

    function getAllkeys() external view returns(string[] memory) {
        return keys;
    }

    function getAllAccounts() external view returns (address[] memory) {
        return accounts;
    }

    function getAllLTokens() external view returns(address[] memory) {
        return LTokenList;
    }

    function accountsOwnedBy(address user)
        external
        view
        returns (address[] memory userAccounts) 
    {
        userAccounts = new address[](accounts.length);
        uint index = 0;
        for (uint i = 0; i < accounts.length; i++) {
            if (ownerFor[accounts[i]] == user) {
                userAccounts[index] = accounts[i];
                index++;
            }
        }
    }

    // Helper functions

    function updateLToken(address lToken, address newLToken) internal {
        uint len = LTokenList.length;
        for(uint i; i < len; ++i) {
            if(LTokenList[i] == lToken) {
                LTokenList[i] = newLToken;
                break;
            }
        }
    }

    function removeLToken(address underlying) internal {
        uint len = LTokenList.length;
        // Copy the last element in place of token and pop
        for(uint i; i < len; ++i) {
            if (underlying == LTokenList[i]) {
                LTokenList[i] = LTokenList[len - 1];
                LTokenList.pop();
                break;
            }
        }
    }

    function removeKey(string calldata id) internal {
        uint len = keys.length;
        bytes32 keyHash = keccak256(abi.encodePacked(id));
        for(uint i; i < len; ++i) {
            if (keyHash == keccak256(abi.encodePacked((keys[i])))) {
                keys[i] = keys[len - 1];
                keys.pop();
                break;
            }
        }
    }
}