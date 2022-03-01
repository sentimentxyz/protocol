// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Utils {
    function isPresent(address[] memory accounts, address account) external pure returns (bool) {
         for(uint i = 0; i < accounts.length; i++) {
            if(accounts[i] == account) return true;
        }
        return false;
    }
}