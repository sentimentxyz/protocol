// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from "./Errors.sol";

abstract contract Ownable {

    address public admin;

    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _admin) {
        admin = _admin;
    }

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) external virtual adminOnly {
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
        
    }
}