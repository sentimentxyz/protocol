// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IRateModel} from "../core/IRateModel.sol";
import {IRegistry} from "../core/IRegistry.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

interface ILToken {
    event ReservesRedeemed(address indexed treasury, uint value);

    function initialize(
        address _admin,
        ERC20 _asset,
        string calldata _name,
        string calldata _symbol,
        IRegistry _registry,
        uint _reserveFactor
    ) external;
    function initializeDependencies(string calldata) external;
    
    function registry() external returns (IRegistry);
    function rateModel() external returns (IRateModel);
    function accountManager() external returns (address);

    function lendTo(address account, uint value) external returns (bool);
    function getBorrowBalance(address account) external view returns (uint);
    function collectFrom(address account, uint value) external returns (bool);
}