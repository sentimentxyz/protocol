// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Errors.sol";

abstract contract Ownable {

    address public admin;

    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) public virtual adminOnly {
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
        
    }
}