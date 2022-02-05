// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Base.sol";
import "./utils/Errors.sol";
import "./utils/ContractNames.sol";
import "./utils/Pausable.sol";
import "./interface/IPriceFeed.sol";
import "./interface/ILToken.sol";
import "./interface/IAccount.sol";
import "./interface/IAccountManager.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

contract RiskEngine is Pausable, Base {
    using PRBMathUD60x18 for uint;

    uint public constant balanceToBorrowThreshold = 12 * 1e17; // 1.2

    constructor(address _addressProvider) {
        admin = msg.sender;
        addressProvider = IAddressProvider(_addressProvider);
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

    function isLiquidatable(address account) public returns (bool) {
        return false;
        // return _isAccountHealthy(_currentAccountBalance(account), _currentAccountBorrows(account));
    }

    // TODO Implement storedAccountBalance view func

    function currentAccountBalance(address account) public view returns (uint) {
        return _currentAccountBalance(account);
    }

    function currentAccountBorrows(address account) public returns (uint) {
        return _currentAccountBorrows(account);
    }

    // Internal Functions
    function _currentAccountBalance(address account) internal view returns (uint) {
        address[] memory assets = IAccount(account).getAssets();
        uint assetsLen = assets.length;
        uint totalBalance = 0;
        for(uint i = 0; i < assetsLen; ++i) {
            totalBalance += _valueInWei(
                assets[i], 
                IERC20(assets[i]).balanceOf(account)
                );
        }
        return totalBalance + account.balance;
    }

    function _currentAccountBorrows(address account) internal returns (uint) {
        if(IAccount(account).hasNoDebt()) return 0;
        address[] memory borrows = IAccount(account).getBorrows();
        uint borrowsLen = borrows.length;
        uint totalBorrows = 0;
        for(uint i = 0; i < borrowsLen; ++i) {
            ILToken lToken = _LTokenAddressFor(borrows[i]);
            totalBorrows += _valueInWei(
                borrows[i],
                lToken.currentBorrowBalance(account)
            );
        }
        return totalBorrows;
    }

    function _valueInWei(address token, uint value) internal view returns (uint) {
        return IPriceFeed(getAddress(ContractNames.FeedAggregator)).getPrice(token).mul(value);
    }

    function _isAccountHealthy(uint accountBalance, uint accountBorrows) internal pure returns (bool) {
        return (accountBorrows == 0) ? true :
            (accountBalance.div(accountBorrows) > balanceToBorrowThreshold);
    }

    function _LTokenAddressFor(address token) internal view returns (ILToken) {
        return ILToken(addressProvider.getLToken(token));
    }
}