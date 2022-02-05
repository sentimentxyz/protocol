// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Base.sol";
import "./utils/Pausable.sol";
import "./utils/ContractNames.sol";
import "./interface/IAccount.sol";
import "./proxy/BeaconProxy.sol";

contract AccountFactory is Pausable, Base {

    constructor (address _addressProvider) {
        admin = msg.sender;
        addressProvider = IAddressProvider(_addressProvider);
    }

    function create() public returns (address account) {
        account = address(
            new BeaconProxy(
                getAddress(ContractNames.AccountBeacon),
                getAddress(ContractNames.AccountManager)
            )
        );
        IAccount(account).initialize(address(addressProvider));
    }
}