// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/proxy/Clones.sol';
import "./interface/IAccount.sol";
import "./proxy/BeaconProxy.sol";
import "./interface/IBeaconProxy.sol";

contract AccountFactory {

    address public beaconImplementation;
    address public beaconProxyImplementation;

    constructor (address _beacon, address _beaconProxy) {
        beaconImplementation = _beacon;
        beaconProxyImplementation = _beaconProxy;
    }

    function create(address accountManager) public returns (address account) {
        account = Clones.clone(beaconProxyImplementation);
        IBeaconProxy(account).initializeProxy(beaconImplementation, accountManager);
        IAccount(account).initialize(accountManager);
    }
}