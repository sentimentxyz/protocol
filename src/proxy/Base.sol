// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {StorageSlot} from "../utils/Storage.sol";
import {Errors} from "../utils/Errors.sol";

abstract contract BaseProxy {

    bytes32 private constant _ADMIN_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

    event AdminChanged(address previousAdmin, address newAdmin);

    modifier adminOnly() {
        if (msg.sender != getAdmin()) revert Errors.AdminOnly();
        _;
    }

    function changeAdmin(address newAdmin) public adminOnly {
        _setAdmin(newAdmin);
    }

    function getAdmin() public view returns (address) {
        return StorageSlot.getAddressAt(_ADMIN_SLOT);
    }

    function _setAdmin(address admin) internal {
        if (admin == address(0)) revert Errors.ZeroAddress();
        emit AdminChanged(getAdmin(), admin);
        StorageSlot.setAddressAt(_ADMIN_SLOT, admin);
    }

    function getImplementation() public virtual returns (address);

    function _delegate(address impl) internal virtual {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)

            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    fallback() external {
        _delegate(getImplementation());
    }
}