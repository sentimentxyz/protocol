// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors as E} from "../../utils/Errors.sol";

contract Errors {
    bytes public adminOnly = abi.encodeWithSelector(E.AdminOnly.selector);
    bytes public zeroAddress = abi.encodeWithSelector(E.ZeroAddress.selector);
    bytes public contractPaused = abi.encodeWithSelector(E.ContractPaused.selector);
    bytes public outstandingDebt = abi.encodeWithSelector(E.OutstandingDebt.selector);
    bytes public accountsNotFound = abi.encodeWithSelector(E.AccountsNotFound.selector);
    bytes public accountOwnerOnly = abi.encodeWithSelector(E.AccountOwnerOnly.selector);
    bytes public contractNotPaused = abi.encodeWithSelector(E.ContractNotPaused.selector);
    bytes public lTokenUnavailable = abi.encodeWithSelector(E.LTokenUnavailable.selector);
    bytes public ethTransferFailer = abi.encodeWithSelector(E.ETHTransferFailure.selector);
    bytes public accountManagerOnly = abi.encodeWithSelector(E.AccountManagerOnly.selector);
    bytes public priceFeedUnavailable = abi.encodeWithSelector(E.PriceFeedUnavailable.selector);
    bytes public controllerUnavailable = abi.encodeWithSelector(E.ControllerUnavailable.selector);
    bytes public riskThresholdBreached = abi.encodeWithSelector(E.RiskThresholdBreached.selector);
    bytes public functionCallRestricted = abi.encodeWithSelector(E.FunctionCallRestricted.selector);
    bytes public accountNotLiquidatable = abi.encodeWithSelector(E.AccountNotLiquidatable.selector);
    bytes public collateralTypeRestricted = abi.encodeWithSelector(E.CollateralTypeRestricted.selector);
    bytes public contractAlreadyInitialized = abi.encodeWithSelector(E.ContractAlreadyInitialized.selector);
    bytes public accountDeactivationFailure = abi.encodeWithSelector(E.AccountDeactivationFailure.selector);
}