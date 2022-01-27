// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Errors.sol";
import "./interface/IERC20.sol";
import "./dependencies/SafeERC20.sol";


// TODO Reduce total number of functions in this contract to minimize bytecode
contract Account {
    using SafeERC20 for IERC20;
    using SafeERC20 for address;

    address[] public assets;
    address[] public borrows;

    address public ownerAddr;
    address public accountManagerAddr;

    modifier accountManagerOnly() {
        if(msg.sender != accountManagerAddr) revert Errors.AccountManagerOnly();
        _;
    }

    function initialize(address _accountManagerAddr) public {
        if(accountManagerAddr != address(0)) revert Errors.AccountAlreadyInitialized();
        accountManagerAddr = _accountManagerAddr;
    }

    function activateFor(address _ownerAddr) public accountManagerOnly {
        ownerAddr = _ownerAddr;
    }

    function deactivate() public accountManagerOnly {
        delete assets;
        ownerAddr = address(0);
    }

    function getArray(bool flag) external view returns (address[] memory) {
        if(!flag) return assets;
        else return borrows;
    }

    function addToArray(bool flag, address tokenAddr) external accountManagerOnly {
        if(!flag) assets.push(tokenAddr);
        else borrows.push(tokenAddr);
    }

     function removeFromArray(bool flag, address tokenAddr) external accountManagerOnly {
         address[] storage arr = (flag) ? borrows : assets;
         uint len = arr.length;
        // Copy the last element in place of tokenAddr and pop
        for(uint i = 0; i < len; ++i) {
            if(arr[i] == tokenAddr) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
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
        for(uint i = 0; i < assets.length; ++i) {
            IERC20(assets[i]).transfer(
                toAddress, 
                IERC20(assets[i]).balanceOf(address(this))
            );
        }
        (bool success, ) = toAddress.call{value: address(this).balance}("");
        if(!success) revert Errors.ETHTransferFailure();
    }

    receive() external payable {}
}
