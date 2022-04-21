// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

/**
    @title Registry Contract
    @notice This contract stores:
        1. Address of all credit accounts as well their owners
        2. LToken addresses and Token->LToken mapping
        3. Address of all deployed protocol contracts
*/
contract Registry is Ownable, IRegistry {

    /* -------------------------------------------------------------------------- */
    /*                              STORAGE VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Utility variable to indicate if contract is initialized
    bool private initialized;

    /// @notice List of contracts
    /// @dev Contract Name should be separated by _ and in all caps Ex. (REGISTRY, RATE_MODEL)
    string[] public keys;

    /// @notice List of credit accounts
    address[] public accounts;

    /// @notice List of lTokens
    address[] public lTokens;

    /// @notice Mapping indicating owner for given account (account => owner)
    mapping(address => address) public ownerFor;

    /// @notice Mapping indicating LToken for given token (token => LToken)
    mapping(address => address) public LTokenFor;

    /// @notice Mapping indication address for given contract (contractName => contract)
    mapping(string => address) public addressFor;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier accountManagerOnly() {
        if (msg.sender != addressFor['ACCOUNT_MANAGER'])
            revert Errors.AccountManagerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract Initialization function
        @dev Can only be invoked once
    */
    function init() external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        initOwnable(msg.sender);
    }

    /**
        @notice Sets contract address for a given contract id
        @dev If address is 0x0 it removes the address from keys.
        If addressFor[id] returns 0x0 then the contract id is added to keys
        @param id Contract name, format (REGISTRY, RATE_MODEL)
        @param _address Address of the contract
    */
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

    /**
        @notice Sets LToken address for a specified token
        @dev If underlying token is 0x0 LToken is removed from lTokens
        if the mapping doesn't exist LToken is pushed to lTokens
        if the mapping exist LToken is updated in lTokens
        @param underlying Address of token
        @param lToken Address of LToken
    */
    function setLToken(address underlying, address lToken) external adminOnly {
        if (LTokenFor[underlying] == address(0)) {
            if (lToken == address(0)) revert Errors.ZeroAddress();
            lTokens.push(lToken);
        }
        else if (lToken == address(0)) removeLToken(LTokenFor[underlying]);
        else updateLToken(LTokenFor[underlying], lToken);

        LTokenFor[underlying] = lToken;
    }

    /**
        @notice Adds account and sets owner of the account
        @dev Adds account to accounts and stores owner for the account.
        Event AccountCreated(account, owner) is emitted
        @param account Address of credit account
        @param owner Address of owner of the credit account
    */
    function addAccount(address account, address owner)
        external
        accountManagerOnly
    {
        ownerFor[account] = owner;
        accounts.push(account);
        emit AccountCreated(account, owner);
    }

    /**
        @notice Updates owner of a credit account
        @param account Address of credit account
        @param owner Address of owner of the credit account
    */
    function updateAccount(address account, address owner)
        external
        accountManagerOnly
    {
        ownerFor[account] = owner;
    }

    /**
        @notice Closes credit account
        @dev Sets address of owner for the account to 0x0
        @param account Address of account to close
    */
    function closeAccount(address account) external accountManagerOnly {
        ownerFor[account] = address(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                               VIEW FUNCTIONS                               */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns all contract names in registry
        @return keys List of contract names
    */
    function getAllKeys() external view returns(string[] memory) {
        return keys;
    }

    /**
        @notice Returns all credit accounts in registry
        @return accounts List of credit accounts
    */
    function getAllAccounts() external view returns (address[] memory) {
        return accounts;
    }

    /**
        @notice Returns all lTokens in registry
        @return lTokens List of lTokens
    */
    function getAllLTokens() external view returns(address[] memory) {
        return lTokens;
    }

    /**
        @notice Returns all accounts owned by a specific user
        @param user Address of user
        @return userAccounts List of credit accounts
    */
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
        assembly { mstore(userAccounts, index) }
    }

    /* -------------------------------------------------------------------------- */
    /*                              HELPER FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function updateLToken(address lToken, address newLToken) internal {
        uint len = lTokens.length;
        for(uint i; i < len; ++i) {
            if(lTokens[i] == lToken) {
                lTokens[i] = newLToken;
                break;
            }
        }
    }

    function removeLToken(address underlying) internal {
        uint len = lTokens.length;
        for(uint i; i < len; ++i) {
            if (underlying == lTokens[i]) {
                lTokens[i] = lTokens[len - 1];
                lTokens.pop();
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