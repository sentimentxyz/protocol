// ABOUTME: Recovery implementation for LToken contracts during protocol deprecation
// ABOUTME: Extracts available liquidity to multisig while maintaining upgradeability

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LToken} from "../../src/tokens/LToken.sol";
import {IERC20} from "../../src/interface/tokens/IERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Errors} from "../../src/utils/Errors.sol";

contract LTokenExtract is LToken {
    using SafeTransferLib for IERC20;

    event Recovered(address indexed asset, uint256 amount);

    bool public fundsRecovered;
    address constant MULTISIG = 0x000000000000000000000000000000000000dEaD;

    function recoverFunds() external nonReentrant returns (uint256 amount) {
        require(!fundsRecovered, "Already recovered");
        
        updateState();
        
        uint256 totalAssets = totalAssets();
        uint256 totalBorrows = borrows;
        
        require(totalAssets > totalBorrows, "No liquidity");
        
        amount = totalAssets - totalBorrows;
        fundsRecovered = true;
        
        IERC20(asset).safeTransfer(MULTISIG, amount);
        
        emit Recovered(address(asset), amount);
    }

}