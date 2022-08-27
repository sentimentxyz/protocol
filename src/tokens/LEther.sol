// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {LToken} from "./LToken.sol";
import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

/**
    @title Lending Token for Ether
    @notice Lending Token contract for Ether with WETH as underlying asset
*/
contract LEther is LToken {
    using Helpers for address;

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Wraps Eth sent by the user and deposits into the LP
            Transfers shares to the user denoting the amount of Eth deposited
        @dev Emits Deposit(caller, owner, assets, shares)
    */
    function depositEth() external payable {
        uint assets = msg.value;
        uint shares = previewDeposit(assets);
        require(shares != 0, "ZERO_SHARES");
        IWETH(address(asset)).deposit{value: assets}();
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, msg.sender, assets, shares);
    }

    /**
        @notice Unwraps Eth and transfers it to the caller
            Amount of Eth transferred will be the total underlying assets that
            are represented by the shares
        @dev Emits Withdraw(caller, receiver, owner, assets, shares);
        @param shares Amount of shares to redeem
    */
    function redeemEth(uint shares) external {
        uint assets = previewRedeem(shares);
        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);
        IWETH(address(asset)).withdraw(assets);
        msg.sender.safeTransferEth(assets);
    }

    receive() external payable {}
}