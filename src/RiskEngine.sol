// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Errors.sol";
import "./interface/IERC20.sol";
import "./interface/IOracle.sol";
import "./interface/ILToken.sol";
import "./interface/IAccount.sol";
import "./interface/IAccountManager.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

contract RiskEngine {
    using PRBMathUD60x18 for uint;

    address public admin;
    address public oracleAddr;
    address public accountManagerAddr;
    uint public constant balanceToBorrowThreshold = 12 * 1e17; // 1.2

    event UpdateAccountManagerAddress(address indexed accountManagerAddr);

    constructor(address _oracleAddr) {
        admin = msg.sender;
        oracleAddr = _oracleAddr;
    }

    function isBorrowAllowed(
        address accountAddr, 
        address tokenAddr, 
        uint value
    )
    public returns (bool) 
    {
        uint borrowAmt = _valueInWei(tokenAddr, value);
        uint newAccountBalance = _currentAccountBalance(accountAddr) + borrowAmt;
        uint newAccountBorrow = _currentAccountBorrows(accountAddr) + borrowAmt;
        return _isAccountHealthy(newAccountBalance, newAccountBorrow);
    }

    function isWithdrawAllowed(
        address accountAddr, 
        address tokenAddr, 
        uint value
    )
    public returns (bool) 
    {
        uint newAccountBalance = _currentAccountBalance(accountAddr) - _valueInWei(tokenAddr, value);
        return _isAccountHealthy(newAccountBalance, _currentAccountBorrows(accountAddr));
    }

    function isLiquidatable(address accountAddr) public returns (bool) {
        return false;
        // return _isAccountHealthy(_currentAccountBalance(accountAddr), _currentAccountBorrows(accountAddr));
    }

    // TODO Implement storedAccountBalance view func

    function currentAccountBalance(address accountAddr) public view returns (uint) {
        return _currentAccountBalance(accountAddr);
    }

    function currentAccountBorrows(address accountAddr) public returns (uint) {
        return _currentAccountBorrows(accountAddr);
    }

    function setAccountManagerAddr(address _accountManagerAddr) public {
        if(msg.sender != admin) revert Errors.AdminOnly();
        accountManagerAddr = _accountManagerAddr;
        emit UpdateAccountManagerAddress(accountManagerAddr);
    }

    // Internal Functions
    function _currentAccountBalance(address accountAddr) internal view returns (uint) {
        IAccount account = IAccount(accountAddr);
        address[] memory assets = account.getAssets();
        uint assetsLen = assets.length;
        uint totalBalance = 0;
        for(uint i = 0; i < assetsLen; ++i) {
            totalBalance += _valueInWei(
                assets[i], 
                IERC20(assets[i]).balanceOf(accountAddr)
                );
        }
        return totalBalance + accountAddr.balance;
    }

    function _currentAccountBorrows(address accountAddr) internal returns (uint) {
        IAccount account = IAccount(accountAddr);
        if(account.hasNoDebt()) return 0;
        address[] memory borrows = account.getBorrows();
        uint borrowsLen = borrows.length;
        uint totalBorrows = 0;
        for(uint i = 0; i < borrowsLen; ++i) {
            address LTokenAddr = _LTokenAddressFor(borrows[i]);
            totalBorrows += _valueInWei(
                borrows[i],
                ILToken(LTokenAddr).currentBorrowBalance(accountAddr)
            );
        }
        return totalBorrows;
    }

    function _valueInWei(address tokenAddr, uint value) internal view returns (uint) {
        return IOracle(oracleAddr).getPrice(tokenAddr).mul(value);
    }

    function _isAccountHealthy(uint accountBalance, uint accountBorrows) internal pure returns (bool) {
        return (accountBorrows == 0) ? true :
            (accountBalance.div(accountBorrows) > balanceToBorrowThreshold);
    }

    function _LTokenAddressFor(address tokenAddr) internal view returns (address) {
        return IAccountManager(accountManagerAddr).LTokenAddressFor(tokenAddr);
    }
}