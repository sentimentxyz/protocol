// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./Errors.sol";
import "../interface/IERC20.sol";
import "../interface/IAccount.sol";

/// @author Modified from Rari-Capital/Solmate
library Helpers {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if(!success) revert Errors.ETHTransferFailure();
    }

    function balanceOf(address token, address owner) internal view returns (uint) {
        return IERC20(token).balanceOf(owner);
    }

    function withdrawEthFromAcc(address account, address to, uint value) internal {
        (bool success, ) = IAccount(account).exec(to, value, new bytes(0));
        if(!success) revert Errors.ETHTransferFailure();
    }

    function withdrawERC20FromAcc(address account, address to, address token, uint value) internal {
        (bool success, bytes memory data) = IAccount(account).exec(token, 0, 
                abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function approveForAcc(address account, address token, address spender, uint value) internal {
        (bool success, bytes memory data) = IAccount(account).exec(token, 0, 
            abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED"); // TODO Refactor using custom errors
    }
}