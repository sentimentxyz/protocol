// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";

contract Beacon {
    
    address public implementation;
    address public admin;

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _implementation) {
        _setImplementation(_implementation);
        admin = msg.sender;
    }

    modifier adminOnly() {
        if (msg.sender != admin) revert Errors.AdminOnly();
        _;
    }

    function changeAdmin(address newAdmin) public adminOnly {
        admin = newAdmin;
        emit AdminChanged(msg.sender, newAdmin);
    }

    function upgradeTo(address newImplementation) public adminOnly {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        implementation = newImplementation;
    }
}