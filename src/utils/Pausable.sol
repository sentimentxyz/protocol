// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Errors.sol";

abstract contract Pausable is Ownable {
    bool public pause;

    event PauseToggled(address indexed admin, bool pause);

    modifier whenNotPaused() {
        if (pause) revert Errors.ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!pause) revert  Errors.ContractNotPaused();
        _;
    }

    function setPause(bool _pause) public adminOnly {
        pause = _pause;
        emit PauseToggled(msg.sender, pause);
    }
}