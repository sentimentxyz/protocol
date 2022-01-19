// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LToken.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

contract LERC20 is LToken {
    using SafeERC20 for IERC20;
    using PRBMathUD60x18 for uint;
    
    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals,
        address _underlyingAddr,
        address _rateModelAddr,
        address _accountManagerAddr,
        uint _initialExchangeRate
    )
    {
        // Token Metadata
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        underlyingAddr = _underlyingAddr;
        // Market State Variables
        exchangeRate = _initialExchangeRate * 1e18;
        borrowIndex = 1e18;
        // Privileged Addresses
        adminAddr = msg.sender;
        rateModelAddr = _rateModelAddr;
        accountManagerAddr = _accountManagerAddr;
    }

    // Lender Functions
    function deposit(uint value) public {
        _updateState();
        IERC20(underlyingAddr).safeTransferFrom(msg.sender, address(this), value);
        _mint(msg.sender, value.div(exchangeRate));
    }

    function withdraw(uint value) public {
        _updateState();
        IERC20(underlyingAddr).safeTransfer(msg.sender, value);
        _burn(msg.sender, value.div(exchangeRate));
    }
}