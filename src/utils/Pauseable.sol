// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "./Errors.sol";
import {Ownable} from  "./Ownable.sol";

abstract contract Pauseable is Ownable {
    bool public paused;

    event PauseToggled(address indexed admin, bool pause);

    function initializePauseable(address _admin) internal {
        initializeOwnable(_admin);
    }

    modifier whenNotPaused() {
        if (paused) revert Errors.ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert  Errors.ContractNotPaused();
        _;
    }

    function togglePause() external adminOnly {
        paused = !paused;
        emit PauseToggled(msg.sender, paused);
    }
}