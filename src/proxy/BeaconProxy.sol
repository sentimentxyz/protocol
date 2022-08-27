// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseProxy} from "./BaseProxy.sol";
import {Errors} from "../utils/Errors.sol";
import {StorageSlot} from "../utils/Storage.sol";
import {IBeacon} from "../interface/proxy/IBeacon.sol";

contract BeaconProxy is BaseProxy {

    bytes32 private constant _BEACON_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);

    event BeaconUpgraded(address indexed beacon);

    constructor(address _beacon, address _admin) {
        _setAdmin(_admin);
        _setBeacon(_beacon);
    }

    function changeBeacon(address beacon) external adminOnly {
        _setBeacon(beacon);
    }

    function getBeacon() public view returns (address) {
        return StorageSlot.getAddressAt(_BEACON_SLOT);
    }

    function getImplementation() public override returns (address) {
        return IBeacon(getBeacon()).implementation();
    }

    function _setBeacon(address beacon) internal {
        if (beacon == address(0)) revert Errors.ZeroAddress();
        StorageSlot.setAddressAt(_BEACON_SLOT, beacon);
        emit BeaconUpgraded(beacon);
    }
}