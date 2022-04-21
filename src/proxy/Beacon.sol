// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IBeacon} from "../interface/proxy/IBeacon.sol";

contract Beacon is IBeacon, Ownable {
    address public implementation;

    event Upgraded(address indexed implementation);

    constructor(address _implementation) {
        initOwnable(msg.sender);
        _setImplementation(_implementation);
    }

    function upgradeTo(address newImplementation) external adminOnly {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        implementation = newImplementation;
    }
}