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
        uint256 amt
    );
    event Borrow(
        address indexed account,
        address indexed owner,
        address indexed token,
        uint256 amt
    );

    function registry() external returns (IRegistry);

    function riskEngine() external returns (IRiskEngine);

    function accountFactory() external returns (IAccountFactory);

    function controller() external returns (IControllerFacade);

    function init(IRegistry) external;

    function initDep() external;

    function openAccount(address owner) external returns (address);

    function closeAccount(address account) external;

    function repay(
        address account,
        address token,
        uint256 amt
    ) external;

    function borrow(
        address account,
        address token,
        uint256 amt
    ) external;

    function deposit(
        address account,
        address token,
        uint256 amt
    ) external;

    function withdraw(
        address account,
        address token,
        uint256 amt
    ) external;

    function depositEth(address account) external payable;

    function withdrawEth(address, uint256) external;

    function liquidate(address) external;

    function settle(address) external;

    function exec(
        address account,
        address target,
        uint256 amt,
        bytes calldata data
    ) external;

    function approve(
        address account,
        address token,
        address spender,
        uint256 amt
    ) external;

    function toggleCollateralStatus(address token) external;

    function setAssetCap(uint256) external;

    function getInactiveAccountsOf(address owner)
        external
        view
        returns (address[] memory);
}
