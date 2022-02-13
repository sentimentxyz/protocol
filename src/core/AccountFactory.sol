// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BeaconProxy} from "../proxy/BeaconProxy.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";

contract AccountFactory is IAccountFactory {
    address public beacon;

    constructor (address _beacon) {
        beacon = _beacon;
    }

    function create(address accountManager) public returns (address account) {
        account = address(new BeaconProxy(beacon, accountManager));
    }
}