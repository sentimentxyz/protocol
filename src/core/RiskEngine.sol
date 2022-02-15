// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IRiskEngine} from "../interface/core/IRiskEngine.sol";
import {IPriceFeed} from "../interface/priceFeeds/IPriceFeed.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";
import {PRBMathUD60x18} from "@prb-math/contracts/PRBMathUD60x18.sol";

contract RiskEngine is Ownable, IRiskEngine {
    using PRBMathUD60x18 for uint;

    IPriceFeed public priceFeed;
    IAccountManager public accountManager;
    uint public constant balanceToBorrowThreshold = 12 * 1e17; // 1.2

    constructor(address _priceFeed) Ownable(msg.sender) {
        priceFeed = IPriceFeed(_priceFeed);
    }

    function isBorrowAllowed(
        address accountAddr, 
        address tokenAddr, 
        uint value
    )
    external returns (bool) 
    {
        uint borrowAmt = _valueInWei(tokenAddr, value);
        uint newAccountBalance = _currentAccountBalance(accountAddr) + borrowAmt;
        uint newAccountBorrow = _currentAccountBorrows(accountAddr) + borrowAmt;
        return _isAccountHealthy(newAccountBalance, newAccountBorrow);
    }

    function isWithdrawAllowed(
        address account, 
        address token, 
        uint value
    )
    external returns (bool) 
    {
        if(IAccount(account).hasNoDebt()) return true;
        uint newAccountBalance = _currentAccountBalance(account) - _valueInWei(token, value);
        return _isAccountHealthy(newAccountBalance, _currentAccountBorrows(account));
    }

    function isLiquidatable(address account) external returns (bool) {
        return _isAccountHealthy(_currentAccountBalance(account), _currentAccountBorrows(account));
    }

    // TODO Implement storedAccountBalance view func

    function currentAccountBalance(address account) external view returns (uint) {
        return _currentAccountBalance(account);
    }

    function currentAccountBorrows(address account) external returns (uint) {
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
            address LTokenAddr = _LTokenAddressFor(borrows[i]);
            totalBorrows += _valueInWei(
                borrows[i],
                ILToken(LTokenAddr).getBorrowBalance(account)
            );
        }
        return totalBorrows;
    }

    function _valueInWei(address token, uint value) internal view returns (uint) {
        return priceFeed.getPrice(token).mul(value);
    }

    function _isAccountHealthy(uint accountBalance, uint accountBorrows) internal pure returns (bool) {
        return (accountBorrows == 0) ? true :
            (accountBalance.div(accountBorrows) > balanceToBorrowThreshold);
    }

    function _LTokenAddressFor(address token) internal view returns (address) {
        return accountManager.LTokenAddressFor(token);
    }

    function setAccountManagerAddress(address _accountManager) external adminOnly {
        accountManager = IAccountManager(_accountManager);
    }
}