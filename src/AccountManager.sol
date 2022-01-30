// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Errors.sol";
import "./interface/IERC20.sol";
import "./interface/ILToken.sol";
import "./interface/IAccount.sol";
import "./interface/IRiskEngine.sol";
import "./interface/IController.sol";
import "./dependencies/SafeERC20.sol";
import "./interface/IUserRegistry.sol";
import "./interface/IAccountFactory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract AccountManager {
    using SafeERC20 for IERC20;

    address public adminAddr;
    address public riskEngineAddr;
    address public userRegistryAddr;
    address public accountFactoryAddr;
    
    address[] public inactiveAccounts;
    
    mapping(address => bool) public isCollateralAllowed; // tokenAddr => bool
    mapping(address => address) public LTokenAddressFor; // token => LToken
    mapping(address => address) public controllerAddrFor; // address => controller

    event AccountAssigned(address indexed accountAddr, address indexed ownerAddr);
    event AccountClosed(address indexed accountAddr, address indexed accountOwner);
    event AccountLiquidated(address indexed accountAddr, address indexed accountOwner);
    event Borrow(address indexed accountAddr, address indexed accountOwner, address indexed tokenAddr, uint value);
    event Repay(address indexed accountAddr, address indexed accountOwner, address indexed tokenAddr, uint value);
    event UpdateRiskEngineAddress(address indexed riskEngineAddr);
    event UpdateUserRegistryAddress(address indexed userRegistryAddr);
    event UpdateControllerAddress(address indexed contractAddr,address indexed controllerAddr);
    event UpdateAccountFactoryAddress(address indexed accountFactoryAddr);
    event UpdateLTokenAddress(address indexed tokenAddr, address indexed LTokenAddr);

    constructor(address _riskEngineAddr, address _accountFactoryAddr, address _userRegistryAddr) {
        adminAddr = msg.sender;
        riskEngineAddr = _riskEngineAddr;
        accountFactoryAddr = _accountFactoryAddr;
        userRegistryAddr = _userRegistryAddr;
    }

    modifier onlyOwner(address accountAddr) {
        if(IAccount(accountAddr).owner() != msg.sender) revert Errors.AccountOwnerOnly();
        _;
    }

    modifier onlyAdmin() {
        if(adminAddr != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function openAccount(address ownerAddr) public {
        address accountAddr;
        if(inactiveAccounts.length == 0) {
            accountAddr = IAccountFactory(accountFactoryAddr).create(address(this));
        } else {
            accountAddr = inactiveAccounts[inactiveAccounts.length - 1];
            inactiveAccounts.pop();
        }
        IAccount(accountAddr).activateFor(ownerAddr);
        IUserRegistry(userRegistryAddr).addMarginAccount(ownerAddr, accountAddr);
        emit AccountAssigned(accountAddr, ownerAddr);
    }

    function closeAccount(address accountAddr) public onlyOwner(accountAddr) {
        if(!IAccount(accountAddr).hasNoDebt()) revert Errors.PendingDebt();
        IAccount account = IAccount(accountAddr);
        account.sweepTo(msg.sender);
        account.deactivate();
        IUserRegistry(userRegistryAddr).removeMarginAccount(msg.sender, accountAddr);
        inactiveAccounts.push(accountAddr);
        emit AccountClosed(accountAddr, msg.sender);
    }

    function depositEth(address accountAddr) external payable onlyOwner(accountAddr) {
        (bool success, ) = accountAddr.call{value: msg.value}("");
        if(!success) revert Errors.ETHTransferFailure();
    }

    function withdrawEth(address accountAddr, uint value) public onlyOwner(accountAddr) {
        (bool success, ) = IAccount(accountAddr).exec(msg.sender, value, new bytes(0));
        if(!success) revert Errors.ETHTransferFailure();
    }

    function deposit(
        address accountAddr, 
        address tokenAddr,
        uint value
    ) 
        public onlyOwner(accountAddr) 
    {
        if(!isCollateralAllowed[tokenAddr]) revert Errors.CollateralTypeRestricted();
        if(IERC20(tokenAddr).balanceOf(accountAddr) == 0) IAccount(accountAddr).addAsset(tokenAddr);
        IERC20(tokenAddr).safeTransferFrom(msg.sender, accountAddr, value);
    }

    function withdraw(
        address accountAddr, 
        address tokenAddr, 
        uint value
    ) 
        public onlyOwner(accountAddr) 
    {
        // TODO Add custom error after changing behavior of hasNoDebt() so that 
        // there is a way to execute this without always running isWithdrawAllowed
        require(IAccount(accountAddr).hasNoDebt() ||
            IRiskEngine(riskEngineAddr).isWithdrawAllowed(accountAddr, tokenAddr, value),
            "AccMgr/withdraw: Risky");
        
        (bool success, bytes memory data) = IAccount(accountAddr).exec(tokenAddr, 0, 
                abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED"); // TODO Refactor using custom errors
        
        if(IERC20(tokenAddr).balanceOf(accountAddr) == 0)
            IAccount(accountAddr).removeAsset(tokenAddr);
    }

    function borrow(
        address accountAddr, 
        address tokenAddr, 
        uint value
    ) 
        public onlyOwner(accountAddr)
    { 
        if(LTokenAddressFor[tokenAddr] == address(0)) revert Errors.LTokenUnavailable();
        if(!IRiskEngine(riskEngineAddr).isBorrowAllowed(accountAddr, tokenAddr, value)) 
            revert Errors.RiskThresholdBreached();
        if(tokenAddr != address(0) && IERC20(tokenAddr).balanceOf(accountAddr) == 0) 
            IAccount(accountAddr).addAsset(tokenAddr);
        if(ILToken(LTokenAddressFor[tokenAddr]).lendTo(accountAddr, value))
            IAccount(accountAddr).addBorrow(tokenAddr);
        emit Borrow(accountAddr, msg.sender, tokenAddr, value);
    }

    function repay(
        address accountAddr, 
        address tokenAddr, 
        uint value
    ) 
        public onlyOwner(accountAddr) 
    {
        if(LTokenAddressFor[tokenAddr] == address(0)) revert Errors.LTokenUnavailable();
        _repay(accountAddr, tokenAddr, value);
        emit Repay(accountAddr, msg.sender, tokenAddr, value);
    }

    function liquidate(address accountAddr) public {
        if(!IRiskEngine(riskEngineAddr).isLiquidatable(accountAddr)) revert Errors.AccountNotLiquidatable();
        _liquidate(accountAddr);
        emit AccountLiquidated(accountAddr, IAccount(accountAddr).owner());
    }

    function approve(
        address accountAddr, 
        address tokenAddr,
        address spenderAddr, 
        uint value
    ) public onlyOwner(accountAddr) {
        (bool success, bytes memory data) = IAccount(accountAddr).exec(tokenAddr, 0, 
            abi.encodeWithSelector(IERC20.approve.selector, spenderAddr, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED"); // TODO Refactor using custom errors
    }

    function exec(
        address accountAddr, 
        address targetAddr,
        uint amt,
        bytes4 sig,
        bytes calldata data
    ) public onlyOwner(accountAddr) {
        bool isAllowed;
        address[] memory tokensIn;
        address[] memory tokensOut;
        
        address controllerAddr = controllerAddrFor[targetAddr];
        if(controllerAddr == address(0)) revert Errors.ControllerUnavailable();
        (isAllowed, tokensIn, tokensOut) = 
            IController(controllerAddr).canCall(targetAddr, sig, data);
        if(!isAllowed) revert Errors.FunctionCallRestricted();
        IAccount(accountAddr).exec(targetAddr, amt, bytes.concat(sig, data));
        _updateTokens(accountAddr, tokensIn, tokensOut);
        if(IRiskEngine(riskEngineAddr).isLiquidatable(accountAddr)) revert Errors.RiskThresholdBreached();
    }

    function settle(address accountAddr) public onlyOwner(accountAddr) {
        address[] memory borrows = IAccount(accountAddr).getBorrows();
        for (uint i = 0; i < borrows.length; i++) {
            uint balance = IERC20(borrows[i]).balanceOf(accountAddr);
            if ( balance > 0 ) repay(accountAddr, borrows[i], balance);
        }
    }

    // Admin-Only
    function toggleCollateralState(address tokenAddr) public onlyAdmin {
        isCollateralAllowed[tokenAddr] = !isCollateralAllowed[tokenAddr];
    }

    function setLTokenAddress(address tokenAddr, address LTokenAddr) public onlyAdmin {
        LTokenAddressFor[tokenAddr] = LTokenAddr;
        emit UpdateLTokenAddress(tokenAddr, LTokenAddr);
    }

    function setRiskEngineAddress(address _riskEngineAddr) public onlyAdmin {
        riskEngineAddr = _riskEngineAddr;
        emit UpdateRiskEngineAddress(riskEngineAddr);
    }

    function setUserRegistryAddress(address _userRegistryAddr) public onlyAdmin {
        userRegistryAddr = _userRegistryAddr;
        emit UpdateUserRegistryAddress(userRegistryAddr);
    }

    function setControllerAddress(address contractAddr, address controllerAddr) public onlyAdmin {
        controllerAddrFor[contractAddr] = controllerAddr;
        emit UpdateControllerAddress(contractAddr, controllerAddr);
    }

    function setAccountFactoryAddress(address _accountFactoryAddr) public onlyAdmin {
        accountFactoryAddr = _accountFactoryAddr;
        emit UpdateAccountFactoryAddress(accountFactoryAddr);
    }

    // Internal Functions
    function _repay(address accountAddr, address tokenAddr, uint value) internal {
        ILToken LToken = ILToken(LTokenAddressFor[tokenAddr]);
        bool isEth = tokenAddr == address(0);
        if(value == type(uint).max) value = LToken.currentBorrowBalance(accountAddr);

        if(isEth) {
            (bool success, ) = IAccount(accountAddr).exec(address(LToken), value, new bytes(0));
            if(!success) revert Errors.ETHTransferFailure();
        }
        else {
             (bool success, bytes memory data) = IAccount(accountAddr).exec(tokenAddr, 0, 
                abi.encodeWithSelector(IERC20.transfer.selector, address(LToken), value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED"); // TODO Refactor using custom errors
        }
        
        if(LToken.collectFrom(accountAddr, value) && !isEth) IAccount(accountAddr).removeBorrow(tokenAddr);
        if (!isEth && IERC20(tokenAddr).balanceOf(accountAddr) == 0) IAccount(accountAddr).removeAsset(tokenAddr);
    }

    function _updateTokens(address accountAddr, address[] memory tokensIn, address[] memory tokensOut) internal {
        IAccount account = IAccount(accountAddr);
        uint tokensInLen = tokensIn.length;
        for(uint i = 0; i < tokensInLen; ++i) {
            if(IERC20(tokensIn[i]).balanceOf(accountAddr) == 0)
                IAccount(accountAddr).addAsset(tokensIn[i]);
        }
        
        uint tokensOutLen = tokensOut.length;
        for(uint i = 0; i < tokensOutLen; ++i) {
            if(IERC20(tokensOut[i]).balanceOf(accountAddr) == 0) 
                account.removeAsset(tokensOut[i]);
        }
    }

    function _liquidate(address accountAddr) internal {
        IAccount account = IAccount(accountAddr);
        address[] memory accountBorrows = account.getBorrows();
        uint borrowLen = accountBorrows.length;

        for(uint i = 0; i < borrowLen; ++i) {
            // TODO Gas optimization by skipping removeAsset in repay
            _repay(accountAddr, accountBorrows[i], type(uint).max);
        }
        account.sweepTo(msg.sender);
    }

    receive() external payable {}
}