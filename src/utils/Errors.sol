// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Errors {
    error AdminOnly();
    error ZeroAddress();
    error ContractPaused();
    error OutstandingDebt();
    error AccountOwnerOnly();
    error TokenNotContract();
    error ContractNotPaused();
    error LTokenUnavailable();
    error EthTransferFailure();
    error AccountManagerOnly();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error IncorrectConstructorArgs();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}