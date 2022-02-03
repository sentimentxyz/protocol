// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Errors.sol";

abstract contract Pausable is Ownable {
    bool public paused;

    event PauseToggled(address indexed admin, bool pause);

    modifier whenNotPaused() {
        if (paused) revert Errors.ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert  Errors.ContractNotPaused();
        _;
    }

    function togglePause() public adminOnly {
        paused = !paused;
        emit PauseToggled(msg.sender, paused);
    }
}