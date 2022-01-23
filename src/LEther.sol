// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LToken.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

contract LEther is LToken {
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
    function deposit() public payable {
        _updateState();
        _mint(msg.sender, msg.value.div(exchangeRate));
    }

    function withdraw(uint value) public {
        _updateState();
        payable(msg.sender).transfer(value);
        _burn(msg.sender, value.div(exchangeRate));
    }

    // Account Manager Functions
    function lendTo(address accountAddr, uint value) public returns (bool) {
        require(msg.sender == accountManagerAddr, "LToken/lendTo: AccountManagerOnly");
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        bool isFirstBorrow = (borrowBalanceFor[accountAddr].principal == 0);
        payable(accountAddr).transfer(value);
        totalBorrows += value;
        borrowBalanceFor[accountAddr].principal += value;
        borrowBalanceFor[accountAddr].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address accountAddr, uint value) public returns (bool) {
        require(msg.sender == accountManagerAddr, "LToken/collectFrom: AccountManagerOnly");
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        totalBorrows -= value;
        borrowBalanceFor[accountAddr].principal -= value;
        borrowBalanceFor[accountAddr].interestIndex = borrowIndex;
        return (borrowBalanceFor[accountAddr].principal == 0);
    }
    
    receive() external payable {}
}