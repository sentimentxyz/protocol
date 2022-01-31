// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/Errors.sol";
import "./utils/SafeERC20.sol";
import "./interface/IRateModel.sol";
import "@prb-math/contracts/PRBMathUD60x18.sol";

abstract contract LToken {
    using SafeERC20 for address;
    using PRBMathUD60x18 for uint;

    // Token Metadata
    string public name;
    string public symbol;
    uint8 public decimals;
    address public underlying;

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
    address public admin;
    IRateModel public rateModel;
    address public accountManager;

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

    modifier accountManagerOnly() {
        if(msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    // Utility Functions
    function updateState() external {
        _updateState();
    }
    
    function currentBorrowBalance(address account) public returns (uint) {
        if(_borrowBalance(account) == 0) return 0;
        _updateState();
        return _borrowBalance(account);
    }

    function storedBorrowBalance(address account) public view returns (uint) {
        return _borrowBalance(account);
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

    function _borrowBalance(address account) internal view returns (uint) {
        if(borrowBalanceFor[account].principal == 0) return 0;
        return (borrowBalanceFor[account].principal * borrowIndex
                / borrowBalanceFor[account].interestIndex);
    }

    function _updateState() internal {
        if(lastUpdated == block.number) return;

        // Retrieve Data
        uint totalDeposits = underlying.balanceOf(address(this));
        uint currentPerBlockBorrowRate =
            rateModel.getBorrowRate(totalDeposits, totalBorrows, totalReserves);

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
    function setAccountManager(address _accountManager) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        accountManager = _accountManager;
        emit UpdateAccountManagerAddress(accountManager);
    }

    function setAdmin(address _admin) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        admin = _admin;
        emit UpdateAdminAddress(admin);
    }

    function setRateModel(address _rateModel) external {
        if(msg.sender != admin) revert Errors.AdminOnly();
        rateModel = IRateModel(_rateModel);
        emit UpdateRateModelAddress(address(rateModel));
    }
}