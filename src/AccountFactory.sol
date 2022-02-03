// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/Pausable.sol";
import "./interface/IAccount.sol";
import "./proxy/BeaconProxy.sol";
import "./interface/IBeaconProxy.sol";

contract AccountFactory is Pausable {

    address public beaconImplementation;

    constructor (address _implementation) {
        admin = msg.sender;
        beaconImplementation = _implementation;
    }

    function create(address accountManager) public returns (address account) {
        account = address(new BeaconProxy(beaconImplementation, accountManager));
        IAccount(account).initialize(accountManager);
    }
}