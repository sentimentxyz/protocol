// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IAccount} from "../interface/core/IAccount.sol";

contract Account is IAccount {
    using Helpers for address;

    uint public activationBlock;
    address public accountManager;

    address[] public assets;
    address[] public borrows;

    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    function init(address _accountManager) external {
        if (accountManager != address(0))
            revert Errors.ContractAlreadyInitialized();
        accountManager = _accountManager;
    }

    function activate() external accountManagerOnly {
        delete assets;
        activationBlock = block.number;
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

    function hasNoDebt() external view returns (bool) {
        return borrows.length == 0;
    }

    function exec(address target, uint amt, bytes calldata data) 
        external
        payable
        accountManagerOnly
        returns (bool, bytes memory)
    {
        (bool success, bytes memory retData) = target.call{value: amt}(data);
        return (success, retData);
    }

    function sweepTo(address toAddress) external accountManagerOnly {
        uint assetsLen = assets.length;
        for(uint i = 0; i < assetsLen; ++i) {
            assets[i].safeTransfer(
                toAddress,
                assets[i].balanceOf(address(this))
            );
        }
        toAddress.safeTransferEth(address(this).balance);
    }

     function _remove(address[] storage arr, address token) internal {
         uint len = arr.length;
        // Copy the last element in place of tokenAddr and pop
        for(uint i = 0; i < len; ++i) {
            if (arr[i] == token) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }

    receive() external payable {}
}
