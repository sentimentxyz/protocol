// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BeaconProxy} from "../proxy/BeaconProxy.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";

contract AccountFactory is IAccountFactory {

    // TODO Rename to beacon
    address public beaconImplementation;

    constructor (address _implementation) {
        beaconImplementation = _implementation;
    }

    function create(address accountManager) public returns (address account) {
        account = address(new BeaconProxy(beaconImplementation, accountManager));
    }
}