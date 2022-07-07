// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Errors {
    error AdminOnly();
    error ZeroAddress();
    error ContractPaused();
    error OutstandingDebt();
    error AccountsNotFound();
    error AccountOwnerOnly();
    error ContractNotPaused();
    error LTokenUnavailable();
    error EthTransferFailure();
    error AccountManagerOnly();
    error PriceFeedUnavailable();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}