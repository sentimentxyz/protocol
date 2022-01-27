// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Errors.sol";
import "./interface/IERC20.sol";
import "./interface/IRateModel.sol";
import "./dependencies/SafeERC20.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

abstract contract LToken {
    using SafeERC20 for IERC20;
    using PRBMathUD60x18 for uint;

    // Token Metadata
    string public name;
    string public symbol;
    uint8 public decimals;
    address public underlyingAddr;

    // Market State Variables
    uint public exchangeRate;
    uint public lastUpdated;
    uint public borrowIndex;
    uint public totalReserves;
    uint public totalBorrows;
    uint public reserveFactor;

    // Borrow accounting
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }
    mapping(address => BorrowSnapshot) public borrowBalanceFor;

    // Privileged addresses
    address public adminAddr;
    address public rateModelAddr;
    address public accountManagerAddr;

    // ERC20 accounting
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ERC20 Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event UpdateAccountManagerAddress(address indexed accountManagerAddr);
    event UpdateAdminAddress(address indexed adminAddr);
    event UpdateRateModelAddress(address indexed rateModelAddr);

    // ERC20 Functions
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    // Utility Functions
    function updateState() external {
        _updateState();
    }
    
    function currentBorrowBalance(address accountAddr) public returns (uint) {
        if(_borrowBalance(accountAddr) == 0) return 0;
        _updateState();
        return _borrowBalance(accountAddr);
    }

    function storedBorrowBalance(address accountAddr) public view returns (uint) {
        return _borrowBalance(accountAddr);
    }

    // Internal Functions
    function _mint(address to, uint256 value) internal {
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _borrowBalance(address accountAddr) internal view returns (uint) {
        if(borrowBalanceFor[accountAddr].principal == 0) return 0;
        return (borrowBalanceFor[accountAddr].principal * borrowIndex
                / borrowBalanceFor[accountAddr].interestIndex);
    }

    function _updateState() internal {
        if(lastUpdated == block.number) return;

        IERC20 underlying = IERC20(underlyingAddr); 

        // Retrieve Data
        uint totalDeposits = underlying.balanceOf(address(this));
        uint currentPerBlockBorrowRate =
            IRateModel(rateModelAddr).getBorrowRate(totalDeposits, totalBorrows, totalReserves);

        // Compute Results
        uint rateFactor = ((block.number - lastUpdated).fromUint()).mul(currentPerBlockBorrowRate);
        uint newBorrowIndex = borrowIndex.mul(1e18 + rateFactor);
        uint interestAccrued = totalBorrows.mul(rateFactor);
        uint newTotalBorrows = totalBorrows + interestAccrued;
        uint newTotalReserves = interestAccrued.mul(reserveFactor) + totalReserves;
        uint newExchangeRate = (totalSupply == 0) ? exchangeRate :
            (totalDeposits + newTotalBorrows - newTotalReserves).div(totalSupply);

        // Store results
        borrowIndex = newBorrowIndex;
        totalBorrows = newTotalBorrows;
        totalReserves = newTotalReserves;
        exchangeRate = newExchangeRate;
        lastUpdated = block.number;
    }

    // Admin-only functions
    function setAccountManagerAddress(address _accountManagerAddr) external {
        if(msg.sender != adminAddr) revert Errors.AdminOnly();
        accountManagerAddr = _accountManagerAddr;
        emit UpdateAccountManagerAddress(accountManagerAddr);
    }

    function setAdmin(address _adminAddr) external {
        if(msg.sender != adminAddr) revert Errors.AdminOnly();
        adminAddr = _adminAddr;
        emit UpdateAdminAddress(adminAddr);
    }

    function setRateModelAddr(address _rateModelAddr) external {
        if(msg.sender != adminAddr) revert Errors.AdminOnly();
        rateModelAddr = _rateModelAddr;
        emit UpdateRateModelAddress(rateModelAddr);
    }
}