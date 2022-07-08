// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IAccount} from "../interface/core/IAccount.sol";

/**
    @title Sentiment Account
    @notice Contract that acts as a dynamic and distributed asset reserve
        which holds a user’s collateral and loaned assets
*/
contract Account is IAccount {
    using Helpers for address;

    /* -------------------------------------------------------------------------- */
    /*                              STATE VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Block number for when the account is activated
    uint public activationBlock;

    /**
        @notice Address of account manager
        @dev If the value is 0x0 the contract is not initialized
    */
    address public accountManager;


    /// @notice A list of ERC-20 assets (Collaterals + Borrows) present in the account
    address[] public assets;

    /// @notice A list of borrowed ERC-20 assets present in the account
    address[] public borrows;

    /// @notice A mapping of ERC-20 assets present in the account
    mapping(address => bool) public hasAsset;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Initializes the account by setting the address of the account
            manager
        @dev Can only be called as long as the address of the accountManager is
            0x0
        @param _accountManager address of the account manager
    */
    function init(address _accountManager) external {
        if (accountManager != address(0))
            revert Errors.ContractAlreadyInitialized();
        accountManager = _accountManager;
    }

    /**
        @notice Activates an account by setting the activationBlock to the
            current block number
    */
    function activate() external accountManagerOnly {
        activationBlock = block.number;
    }

    /**
        @notice Deactivates an account by setting the activationBlock to 0
    */
    function deactivate() external accountManagerOnly {
        activationBlock = 0;
    }

    /**
        @notice Returns a list of ERC-20 assets deposited and borrowed by the owner
        @return assets List of addresses
    */
    function getAssets() external view returns (address[] memory) {
        return assets;
    }

    /**
        @notice Returns a list of ERC-20 assets borrowed by the owner
        @return borrows List of addresses
    */
    function getBorrows() external view returns (address[] memory) {
        return borrows;
    }

    /**
        @notice Adds a given ERC-20 token to the assets list
        @param token Address of the ERC-20 token to add
    */
    function addAsset(address token) external accountManagerOnly {
        assets.push(token);
        hasAsset[token] = true;
    }

    /**
        @notice Adds a given ERC-20 token to the borrows list
        @param token Address of the ERC-20 token to add
    */
    function addBorrow(address token) external accountManagerOnly {
        borrows.push(token);
    }

    /**
        @notice Removes a given ERC-20 token from the assets list
        @param token Address of the ERC-20 token to remove
    */
    function removeAsset(address token) external accountManagerOnly {
        _remove(assets, token);
        hasAsset[token] = false;
    }

    /**
        @notice Removes a given ERC-20 token from the borrows list
        @param token Address of the ERC-20 token to remove
    */
    function removeBorrow(address token) external accountManagerOnly {
        _remove(borrows, token);
    }

    /**
        @notice Returns whether the account has debt or not by checking the length
            of the borrows list
        @return hasNoDebt bool
    */
    function hasNoDebt() external view returns (bool) {
        return borrows.length == 0;
    }

    /**
        @notice Generalized utility function to transact with a given contract
        @param target Address of contract to transact with
        @param amt Amount of Eth to send to the target contract
        @param data Encoded sig + params of the function to transact with in the
            target contract
        @return success True if transaction was successful, false otherwise
        @return retData Data returned by given target contract after
            the transaction
    */
    function exec(address target, uint amt, bytes calldata data)
        external
        payable
        accountManagerOnly
        returns (bool, bytes memory)
    {
        (bool success, bytes memory retData) = target.call{value: amt}(data);
        return (success, retData);
    }

    /**
        @notice Utility function to transfer all assets to a specified account
            and delete all assets
        @param toAddress address of the account to send the assets to
    */
    function sweepTo(address toAddress) external accountManagerOnly {
        uint assetsLen = assets.length;
        for(uint i; i < assetsLen; ++i) {
            assets[i].safeTransfer(
                toAddress,
                assets[i].balanceOf(address(this))
            );
            hasAsset[assets[i]] = false;
        }
        delete assets;
        toAddress.safeTransferEth(address(this).balance);
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @dev Utility function to remove a given address from a list of addresses
        @param arr A list of addresses
        @param token Address to remove
    */
    function _remove(address[] storage arr, address token) internal {
        uint len = arr.length;
        for(uint i; i < len; ++i) {
            if (arr[i] == token) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }

    receive() external payable {}
}