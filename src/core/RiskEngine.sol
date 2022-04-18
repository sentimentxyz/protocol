// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {ILToken} from "../interface/tokens/ILToken.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";
import {IOracle} from "oracle/core/IOracle.sol";
import {IRiskEngine} from "../interface/core/IRiskEngine.sol";
import {IAccountManager} from "../interface/core/IAccountManager.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract RiskEngine is Ownable, IRiskEngine {
    using PRBMathUD60x18 for uint;

    IRegistry public immutable registry;
    IOracle public oracle;
    IAccountManager public accountManager;
    uint public constant balanceToBorrowThreshold = 12 * 1e17; // 1.2

    constructor(IRegistry _registry) {
        initOwnable(msg.sender);
        registry = _registry;
    }

    /// @notice Initializes external dependencies
    function initDep() external adminOnly {
        oracle = IOracle(registry.addressFor('ORACLE'));
        accountManager = IAccountManager(registry.addressFor('ACCOUNT_MANAGER'));
    } 

    function isBorrowAllowed(
        address accountAddr, 
        address tokenAddr, 
        uint value
    )
        external
        view
        returns (bool) 
    {
        uint borrowAmt = _valueInWei(tokenAddr, value);
        return _isAccountHealthy(
            _getBalance(accountAddr) + borrowAmt, 
            _getBorrows(accountAddr) + borrowAmt
        );
    }

    function isWithdrawAllowed(
        address account, 
        address token, 
        uint value
    )
        external
        view
        returns (bool) 
    {
        if (IAccount(account).hasNoDebt()) return true;
        return _isAccountHealthy(
            _getBalance(account) - _valueInWei(token, value),
            _getBorrows(account)
        );
    }

    function isAccountHealthy(address account) external view returns (bool) {
        return _isAccountHealthy(
            _getBalance(account), 
            _getBorrows(account)
        );
    }

    function getBalance(address account) external view returns (uint) {
        return _getBalance(account);
    }

    function getBorrows(address account) external view returns (uint) {
        return _getBorrows(account);
    }

    // Internal Functions
    function _getBalance(address account) internal view returns (uint) {
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

    function _getBorrows(address account) internal view returns (uint) {
        if (IAccount(account).hasNoDebt()) return 0;
        address[] memory borrows = IAccount(account).getBorrows();
        uint borrowsLen = borrows.length;
        uint totalBorrows = 0;
        for(uint i = 0; i < borrowsLen; ++i) {
            address LTokenAddr = registry.LTokenFor(borrows[i]);
            totalBorrows += _valueInWei(
                borrows[i],
                ILToken(LTokenAddr).getBorrowBalance(account)
            );
        }
        return totalBorrows;
    }

    function _valueInWei(address token, uint value)
        internal
        view
        returns (uint) 
    {
        return oracle.getPrice(token).mul(value);
    }

    function _isAccountHealthy(uint accountBalance, uint accountBorrows)
        internal
        pure
        returns (bool) 
    {
        return (accountBorrows == 0) ? true :
            (accountBalance.div(accountBorrows) > balanceToBorrowThreshold);
    }
}