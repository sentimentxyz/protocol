// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IAccount} from "../interface/core/IAccount.sol";

// TODO Reduce total number of functions in this contract to minimize bytecode
contract Account is IAccount {
    using Helpers for address;

    uint public activationBlock;

    address[] public assets;
    address[] public borrows;

    address public owner;
    address public accountManager;

    modifier accountManagerOnly() {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function initialize(address _accountManager) public {
        if(accountManager != address(0)) revert Errors.ContractAlreadyInitialized();
        accountManager = _accountManager;
    }

    function activateFor(address _owner) public accountManagerOnly {
        owner = _owner;
        activationBlock = block.number;
    }

    function deactivate() public accountManagerOnly {
        if (activationBlock == block.number) revert Errors.AccountDeactivationFailure();
        delete assets;
        owner = address(0);
    }

    function getAssets() external view returns (address[] memory) {
        return assets;
    }

    function getBorrows() external view returns (address[] memory) {
        return borrows;
    }

    function addAsset(address token) external accountManagerOnly {
        assets.push(token);
    }

    function addBorrow(address token) external accountManagerOnly {
        borrows.push(token);
    }

    function removeAsset(address token) external accountManagerOnly {
        _remove(assets, token);
    }

    function removeBorrow(address token) external accountManagerOnly {
        _remove(borrows, token);
    }

    function hasNoDebt() public view returns (bool) {
        return borrows.length == 0;
    }

    function exec(address target, uint amt, bytes memory data) 
        public payable accountManagerOnly returns (bool, bytes memory) {
        (bool success, bytes memory retData) = target.call{value: amt}(data);
        return (success, retData);
    }

    function sweepTo(address toAddress) public accountManagerOnly {
        uint assetsLen = assets.length;
        for(uint i = 0; i < assetsLen; ++i) {
            assets[i].safeTransfer(
                toAddress,
                assets[i].balanceOf(address(this))
            );
        }
        toAddress.safeTransferETH(address(this).balance);
    }

     function _remove(address[] storage arr, address token) internal {
         uint len = arr.length;
        // Copy the last element in place of tokenAddr and pop
        for(uint i = 0; i < len; ++i) {
            if(arr[i] == token) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }

    receive() external payable {}
}