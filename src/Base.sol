// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interface/IAddressProvider.sol";

contract Base {
    IAddressProvider public addressProvider;

    function getAddress(bytes32 contractName) public view returns (address) {
        return addressProvider.getAddress(contractName);
    }
}