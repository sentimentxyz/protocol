// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
        require(accountManagerAddr == msg.sender, "Account/accountManagerOnly");
        _;
    }

    function initialize(address _accountManagerAddr) public {
        require(accountManagerAddr == address(0), "Account/AlreadyInitialized");
        accountManagerAddr = _accountManagerAddr;
    }

    function activateFor(address _ownerAddr) public accountManagerOnly {
        ownerAddr = _ownerAddr;
    }

    function deactivate() public accountManagerOnly {
        delete assets;
        ownerAddr = address(0);
    }

    function withdraw(address toAddr, address tokenAddr, uint value) public accountManagerOnly {
        IERC20(tokenAddr).safeTransfer(toAddr, value);
    }

    function withdrawEth(address toAddr, uint value) public accountManagerOnly {
        toAddr.safeTransferETH(value);
    }

    function repay(address LTokenAddr, address tokenAddr, uint value) public accountManagerOnly {
        IERC20(tokenAddr).safeTransfer(LTokenAddr, value);
    }

    function approve(address tokenAddr, address spenderAddr, uint value) public accountManagerOnly {
        IERC20(tokenAddr).safeApprove(spenderAddr, value);
    }

    function getAssets() public view returns (address[] memory) {
        return assets;
    }

    function getBorrows() public view returns (address[] memory) {
        return borrows;
    }

    function addAsset(address tokenAddr) public accountManagerOnly {
        if(_balanceOf(tokenAddr) == 0) assets.push(tokenAddr);
    }

    function addBorrow(address tokenAddr) public accountManagerOnly {
        borrows.push(tokenAddr);
    }

    function removeAsset(address tokenAddr) public accountManagerOnly {
        if(_balanceOf(tokenAddr) == 0) _remove(assets, tokenAddr);
    }

    function removeBorrow(address tokenAddr) public accountManagerOnly {
        _remove(borrows, tokenAddr);
    }

    function hasNoDebt() public view returns (bool) {
        return borrows.length == 0;
    }

    function exec(address target, uint amt, bytes memory data) 
        public payable accountManagerOnly returns (bool) {
        (bool success, ) = target.call{value: amt}(data);
        return success;
    }

    function sweepTo(address toAddress) public accountManagerOnly {
        for(uint i = 0; i < assets.length; ++i) {
            IERC20(assets[i]).transfer(
                toAddress, 
                IERC20(assets[i]).balanceOf(address(this))
            );
        }
        toAddress.safeTransferETH(address(this).balance);
    }

    receive() external payable {}

    // Internal Functions
    function _balanceOf(address tokenAddr) internal view returns (uint) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    function _remove(address[] storage arr, address tokenAddr) internal {
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
}
