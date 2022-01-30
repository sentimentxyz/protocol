// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./LToken.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

contract LEther is LToken {
    using PRBMathUD60x18 for uint;

    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals,
        address _underlying,
        address _rateModel,
        address _accountManager,
        uint _initialExchangeRate
    )
    {
        // Token Metadata
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        underlying = IERC20(_underlying);
        // Market State Variables
        exchangeRate = _initialExchangeRate * 1e18;
        borrowIndex = 1e18;
        // Privileged Addresses
        admin = msg.sender;
        rateModel = IRateModel(_rateModel);
        accountManager = _accountManager;
    }

    // Lender Functions
    function deposit() public payable {
        _updateState();
        _mint(msg.sender, msg.value.div(exchangeRate));
    }

    function withdraw(uint value) public {
        _updateState();
        (bool success, ) = msg.sender.call{value: value}("");
        if(!success) revert Errors.ETHTransferFailure();
        _burn(msg.sender, value.div(exchangeRate));
    }

    // Account Manager Functions
    function lendTo(address account, uint value) public accountManagerOnly returns (bool) {
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        bool isFirstBorrow = (borrowBalanceFor[account].principal == 0);
        (bool success, ) = account.call{value: value}("");
        if(!success) revert Errors.ETHTransferFailure();
        totalBorrows += value;
        borrowBalanceFor[account].principal += value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return isFirstBorrow;
    }

    function collectFrom(address account, uint value) public accountManagerOnly returns (bool) {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        // require(block.number == lastUpdated, "LToken/collectFromStale Market State");
        if(block.number != lastUpdated) _updateState(); // TODO how did it get here w/o updating
        totalBorrows -= value;
        borrowBalanceFor[account].principal -= value;
        borrowBalanceFor[account].interestIndex = borrowIndex;
        return (borrowBalanceFor[account].principal == 0);
    }
    
    receive() external payable {}
}