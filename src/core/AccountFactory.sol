// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../proxy/BeaconProxy.sol";
import "../interface/core/IAccount.sol";
import "../interface/core/IAccountFactory.sol";

contract AccountFactory is IAccountFactory {

    address public beaconImplementation;

    constructor (address _implementation) {
        beaconImplementation = _implementation;
    }

    function create(address accountManager) public returns (address account) {
        account = address(new BeaconProxy(beaconImplementation, accountManager));
        IAccount(account).initialize(accountManager);
    }
}