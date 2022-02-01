// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    error AdminOnly();
    error PendingDebt();
    error AccountsNotFound();
    error AccountOwnerOnly();
    error LTokenUnavailable();
    error ETHTransferFailure();
    error AccountManagerOnly();
    error PriceFeedUnavailable();
    error ControllerUnavailable();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error AccountAlreadyInitialized();
    error AccountDeactivationFailure();
}