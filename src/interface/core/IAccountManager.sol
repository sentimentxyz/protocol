// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRegistry} from "./IRegistry.sol";
import {IRiskEngine} from "./IRiskEngine.sol";
import {IAccountFactory} from "../core/IAccountFactory.sol";
import {IControllerFacade} from "controller/core/IControllerFacade.sol";

interface IAccountManager {
    event AccountAssigned(address indexed account, address indexed owner);
    event AccountClosed(address indexed account, address indexed owner);
    event AccountLiquidated(address indexed account, address indexed owner);
    event Repay(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint amt
    );
    event Borrow(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint amt
    );

    function registry() external returns (IRegistry);
    function riskEngine() external returns (IRiskEngine);
    function accountFactory() external returns (IAccountFactory);
    function controller() external returns (IControllerFacade);
    function init(IRegistry) external;
    function initDep() external;
    function openAccount(address owner) external;
    function closeAccount(address account) external;
    function repay(address account, address token, uint amt) external;
    function borrow(address account, address token, uint amt) external;
    function deposit(address account, address token, uint amt) external;
    function withdraw(address account, address token, uint amt) external;
    function depositEth(address account) payable external;
    function withdrawEth(address, uint) external;
    function liquidate(address) external;
    function settle(address) external;
    function exec(
        address account,
        address target,
        uint amt,
        bytes calldata data
    ) external;
    function approve(
        address account,
        address token,
        address spender,
        uint amt
    ) external;
    function toggleCollateralStatus(address token) external;
    function getInactiveAccountsOf(
        address owner
    ) external view returns (address[] memory);
}
