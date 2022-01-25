// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/proxy/Clones.sol';
import "./interface/IAccount.sol";

contract AccountFactory {

    address public implementation;

    constructor (address _implementation) {
        implementation = _implementation;
    }

    function create(address accountManagerAddr) public returns (address account) {
        account = Clones.clone(implementation);
        IAccount(account).initialize(accountManagerAddr);
    }
}