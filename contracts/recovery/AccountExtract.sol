// ABOUTME: Account implementation that adds fund extraction capability
// ABOUTME: Minimal addition to existing Account functionality for protocol deprecation

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../src/core/Account.sol";
import "../../src/interface/core/IRegistry.sol";
import "../../src/interface/core/IAccountManager.sol";
import "../../src/interface/tokens/IERC20.sol";

contract AccountExtract is Account {
    /// @notice Hardcoded multisig address to receive extracted funds
    address constant MULTISIG = 0x000000000000000000000000000000000000dEaD; // TODO: Update with actual multisig
    
    event Recovered(address indexed position, address indexed owner, address indexed asset, uint256 amount);
    
    function recoverFunds() external {
        // Get account owner from Registry
        address owner = IRegistry(IAccountManager(accountManager).registry()).ownerFor(address(this));
        
        // Loop through all assets and transfer them
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];
            if (asset != address(0)) {
                IERC20 token = IERC20(asset);
                uint256 balance = token.balanceOf(address(this));
                if (balance > 0) {
                    token.transfer(MULTISIG, balance);
                    emit Recovered(address(this), owner, asset, balance);
                }
            }
        }
    }
}