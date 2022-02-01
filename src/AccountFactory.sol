// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/proxy/Clones.sol';
import "./interface/IAccount.sol";

contract AccountFactory {

    address public implementation;

    mapping(address => bool) public marginAccounts;

    constructor (address _implementation) {
        implementation = _implementation;
    }

    function create(address accountManager) public returns (address account) {
        account = Clones.clone(implementation);
        IAccount(account).initialize(accountManager);
        marginAccounts[account] = true;
    }

    function isMarginAccount(address marginAccount) public view returns (bool) {
        return marginAccounts[marginAccount];
    }
}