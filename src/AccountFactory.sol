// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Account.sol";

contract AccountFactory {
    function openAccount(address accountManagerAddr) public returns (address) {
        return address(new Account(accountManagerAddr));
    }
}