// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

contract Registry is Ownable, IRegistry {

    string[] public contractNames;
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
    
    // Account Registry Functions

    function setAddress(string calldata id, address _address) 
        external 
        adminOnly 
    {
        if (addressFor[id] == address(0)) contractNames.push(id);
        addressFor[id] = _address;

        if (_address == address(0)) {
            uint len = contractNames.length;
            for(uint i; i < len; ++i) {
                if (keccak256(abi.encodePacked((contractNames[i]))) == 
                    keccak256(abi.encodePacked(id))) 
                {
                    contractNames[i] = contractNames[len - 1];
                    contractNames.pop();
                    break;
                }
            }
        }
    }

    function setLToken(address underlying, address lToken) external adminOnly {
        if (LTokenFor[underlying] == address(0)) { // Add new LToken
            require(lToken != address(0));
            LTokenList.push(lToken);
        } else if (lToken == address(0)) { // Remove existing LToken
            removeFromLTokenList(LTokenFor[underlying]);
        } else { // Update existing LToken
            updateLTokenList(LTokenFor[underlying], lToken);
        }
        LTokenFor[underlying] = lToken;
    }

    // Array manipulation functions
    function updateLTokenList(address lToken, address newLToken) internal {
        uint len = LTokenList.length;
        for(uint i; i < len; ++i) {
            if(LTokenList[i] == lToken) {
                LTokenList[i] = newLToken;
                break;
            }
        }
    }

    function removeFromLTokenList(address token) internal {
        uint len = LTokenList.length;
        // Copy the last element in place of token and pop
        for(uint i; i < len; ++i) {
            if (LTokenList[i] == token) {
                LTokenList[i] = LTokenList[len - 1];
                LTokenList.pop();
                break;
            }
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

    function getAllContractNames() external view returns(string[] memory) {
        return contractNames;
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
}