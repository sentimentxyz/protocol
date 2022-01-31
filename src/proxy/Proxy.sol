// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {StorageSlot} from "../utils/Storage.sol";
import {Errors} from "../utils/Errors.sol";
import "./Base.sol";

contract Proxy is BaseProxy {

    bytes32 private constant _IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    event Upgraded(address newImplementation);

    constructor(address _logic) {
        _setImplementation(_logic);
        _setAdmin(msg.sender);
    }

    function changeImplementation(address implementation) public adminOnly {
        _setImplementation(implementation);
    }

    function getImplementation() public override view returns (address) {
        return StorageSlot.getAddressAt(_IMPL_SLOT);
    }

    function _setImplementation(address implementation) internal {
        if (implementation == address(0)) revert Errors.ZeroAddress();
        StorageSlot.setAddressAt(_IMPL_SLOT, implementation);
        emit Upgraded(implementation);
    }
}