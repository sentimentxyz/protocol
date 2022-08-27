// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {Errors} from "./Errors.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {IAccount} from "../interface/core/IAccount.sol";

/// @author Modified from Rari-Capital/Solmate
library Helpers {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeTransferEth(address to, uint256 amt) internal {
        (bool success, ) = to.call{value: amt}(new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function balanceOf(address token, address owner) internal view returns (uint) {
        return IERC20(token).balanceOf(owner);
    }

    function withdrawEth(address account, address to, uint amt) internal {
        (bool success, ) = IAccount(account).exec(to, amt, new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function withdraw(address account, address to, address token, uint amt) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
                abi.encodeWithSelector(IERC20.transfer.selector, to, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(address account, address token, address spender, uint amt) internal {
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
            abi.encodeWithSelector(IERC20.approve.selector, spender, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function isContract(address token) internal view returns (bool) {
        return token.code.length > 0;
    }

    function functionDelegateCall(
        address target,
        bytes calldata data
    ) internal {
        if (!isContract(target)) Errors.AddressNotContract;
        (bool success, ) = target.delegatecall(data);
        require(success, "CALL_FAILED");
    }
}