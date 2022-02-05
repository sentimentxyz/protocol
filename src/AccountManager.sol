// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Base.sol";
import "./utils/Errors.sol";
import "./utils/Helpers.sol";
import "./utils/Pausable.sol";
import "./utils/ContractNames.sol";
import "./interface/ILToken.sol";
import "./interface/IAccount.sol";
import "./interface/IRiskEngine.sol";
import "./interface/IController.sol";
import "./interface/IUserRegistry.sol";
import "./interface/IAccountFactory.sol";

contract AccountManager is Pausable, Base {
    using Helpers for address;
    
    address[] public inactiveAccounts;
    
    mapping(address => bool) public isCollateralAllowed; // tokenAddr => bool
    mapping(address => address) public controllerAddrFor; // address => controller

    event AccountAssigned(address indexed accountAddr, address indexed ownerAddr);
    event AccountClosed(address indexed accountAddr, address indexed accountOwner);
    event AccountLiquidated(address indexed accountAddr, address indexed accountOwner);
    event Borrow(address indexed accountAddr, address indexed accountOwner, address indexed tokenAddr, uint value);
    event Repay(address indexed accountAddr, address indexed accountOwner, address indexed tokenAddr, uint value);
    event UpdateControllerAddress(address indexed contractAddr,address indexed controllerAddr);

    constructor(address _addressProvider) {
        admin = msg.sender;
        addressProvider = IAddressProvider(_addressProvider);
    }

    modifier onlyOwner(address account) {
        if(
            !IUserRegistry(getAddress(ContractNames.UserRegistry)).isValidOwner(msg.sender, account)
        ) revert Errors.AccountOwnerOnly();
        _;
    }

    function openAccount(address owner) public {
        address account;
        if(inactiveAccounts.length == 0) {
            account = IAccountFactory(getAddress(ContractNames.AccountFactory)).create();
        } else {
            account = inactiveAccounts[inactiveAccounts.length - 1];
            inactiveAccounts.pop();
        }
        IAccount(account).activateFor(owner);
        IUserRegistry(getAddress(ContractNames.UserRegistry)).addMarginAccount(owner, account);
        emit AccountAssigned(account, owner);
    }

    function closeAccount(address _account) public onlyOwner(_account) {
        IAccount account = IAccount(_account);
        if(account.hasNoDebt()) revert Errors.PendingDebt();
        account.sweepTo(msg.sender);
        account.deactivate();
        IUserRegistry(getAddress(ContractNames.UserRegistry)).removeMarginAccount(msg.sender, address(account));
        inactiveAccounts.push(address(account));
        emit AccountClosed(address(account), msg.sender);
    }

    function depositEth(address account) external payable onlyOwner(account) {
        account.safeTransferETH(msg.value);
    }

    function withdrawEth(address account, uint value) public onlyOwner(account) {
        account.withdrawEthFromAcc(msg.sender, value);
    }

    function deposit(
        address account, 
        address token,
        uint value
    ) 
        public onlyOwner(account) 
    {
        if(!isCollateralAllowed[token]) revert Errors.CollateralTypeRestricted();
        if(token.balanceOf(account) == 0) IAccount(account).addAsset(address(token));
        token.safeTransferFrom(msg.sender, account, value);
    }

    function withdraw(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account) 
    {
        // TODO Add custom error after changing behavior of hasNoDebt() so that 
        // there is a way to execute this without always running isWithdrawAllowed
        require(IAccount(account).hasNoDebt() ||
            IRiskEngine(getAddress(ContractNames.RiskEngine)).isWithdrawAllowed(account, token, value),
            "AccMgr/withdraw: Risky");
        account.withdrawERC20FromAcc(msg.sender, token, value);
        if(token.balanceOf(account) == 0)
            IAccount(account).removeAsset(token);
    }

    function borrow(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account)
    { 
        ILToken lToken = _getLToken(token);
        if(address(lToken) == address(0)) revert Errors.LTokenUnavailable();
        if(!IRiskEngine(getAddress(ContractNames.RiskEngine)).isBorrowAllowed(account, token, value)) 
            revert Errors.RiskThresholdBreached();
        if(token != address(0) && token.balanceOf(account) == 0) 
            IAccount(account).addAsset(token);
        if(lToken.lendTo(account, value))
            IAccount(account).addBorrow(token);
        emit Borrow(account, msg.sender, token, value);
    }

    function repay(
        address account, 
        address token, 
        uint value
    ) 
        public onlyOwner(account) 
    {
        if(address(_getLToken(token)) == address(0)) revert Errors.LTokenUnavailable();
        _repay(account, token, value);
        emit Repay(account, msg.sender, token, value);
    }

    function liquidate(address account) public {
        if(!IRiskEngine(getAddress(ContractNames.RiskEngine)).isLiquidatable(account)) revert Errors.AccountNotLiquidatable();
        _liquidate(account);
        emit AccountLiquidated(account, IAccount(account).owner());
    }

    function approve(
        address account, 
        address token,
        address spender, 
        uint value
    ) public onlyOwner(account) {
        account.approveForAcc(token, spender, value);
    }

    function exec(
        address account, 
        address target,
        uint amt,
        bytes4 sig,
        bytes calldata data
    ) public onlyOwner(account) {
        bool isAllowed;
        address[] memory tokensIn;
        address[] memory tokensOut;
        
        address controller = controllerAddrFor[target];
        if(controller == address(0)) revert Errors.ControllerUnavailable();
        (isAllowed, tokensIn, tokensOut) = 
            IController(controller).canCall(target, sig, data);
        if(!isAllowed) revert Errors.FunctionCallRestricted();
        IAccount(account).exec(target, amt, bytes.concat(sig, data));
        _updateTokens(account, tokensIn, tokensOut);
        if(
            IRiskEngine(getAddress(ContractNames.RiskEngine)).isLiquidatable(account)
        ) revert Errors.RiskThresholdBreached();
    }

    function settle(address account) public onlyOwner(account) {
        address[] memory borrows = IAccount(account).getBorrows();
        for (uint i = 0; i < borrows.length; i++) {
            uint balance = borrows[i].balanceOf(account);
            if ( balance > 0 ) repay(account, borrows[i], balance);
        }
    }

    // Admin-Only
    function toggleCollateralState(address token) public adminOnly {
        isCollateralAllowed[token] = !isCollateralAllowed[token];
    }

    function setControllerAddress(address target, address controller) public adminOnly {
        controllerAddrFor[target] = controller;
        emit UpdateControllerAddress(target, controller);
    }

    // Internal Functions
    function _repay(address account, address token, uint value) internal {
        ILToken LToken = _getLToken(token);
        bool isEth = token == address(0);
        if(value == type(uint).max) value = LToken.currentBorrowBalance(account);

        if(isEth) account.withdrawEthFromAcc(address(LToken), value);
        else account.withdrawERC20FromAcc(address(LToken), token, value);
        
        if(LToken.collectFrom(account, value) && !isEth) IAccount(account).removeBorrow(token);
        if (!isEth && IERC20(token).balanceOf(account) == 0) IAccount(account).removeAsset(token);
    }

    function _updateTokens(address account, address[] memory tokensIn, address[] memory tokensOut) internal {
        uint tokensInLen = tokensIn.length;
        for(uint i = 0; i < tokensInLen; ++i) {
            if(tokensIn[i].balanceOf(account) == 0)
                IAccount(account).addAsset(tokensIn[i]);
        }
        
        uint tokensOutLen = tokensOut.length;
        for(uint i = 0; i < tokensOutLen; ++i) {
            if(tokensOut[i].balanceOf(account) == 0) 
                IAccount(account).removeAsset(tokensOut[i]);
        }
    }

    function _liquidate(address _account) internal {
        IAccount account = IAccount(_account);
        address[] memory accountBorrows = account.getBorrows();
        uint borrowLen = accountBorrows.length;

        for(uint i = 0; i < borrowLen; ++i) {
            // TODO Gas optimization by skipping removeAsset in repay
            _repay(_account, accountBorrows[i], type(uint).max);
        }
        account.sweepTo(msg.sender);
    }

    function _getLToken(address _token) internal view returns (ILToken) {
        return ILToken(addressProvider.getLToken(_token));
    }

    receive() external payable {}
}