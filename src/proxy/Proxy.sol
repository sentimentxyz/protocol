// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseProxy} from "./BaseProxy.sol";
import {Errors} from "../utils/Errors.sol";
import {StorageSlot} from "../utils/Storage.sol";
import {Helpers} from "../utils/Helpers.sol";

contract Proxy is BaseProxy {

    bytes32 private constant _IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    event Upgraded(address indexed newImplementation);

    constructor(address _logic) {
        _setImplementation(_logic);
        _setAdmin(msg.sender);
    }

    function changeImplementation(address implementation) external adminOnly {
        _setImplementation(implementation);
    }

    function upgradeToAndCall(address implementation, bytes calldata data) external adminOnly {
        _upgradeToAndCall(implementation, data);
    }

    function getImplementation() public override view returns (address) {
        return StorageSlot.getAddressAt(_IMPL_SLOT);
    }

    function _setImplementation(address implementation) internal {
        if (implementation == address(0)) revert Errors.ZeroAddress();
        StorageSlot.setAddressAt(_IMPL_SLOT, implementation);
        emit Upgraded(implementation);
    }

    function _upgradeToAndCall(address implementation, bytes calldata data) internal {
        _setImplementation(implementation);
        if (data.length > 0) Helpers.functionDelegateCall(implementation, data);
    }
}