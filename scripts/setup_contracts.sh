#!/bin/bash

RPC_URL=<RPC_URL>
PRIVATE_KEY=<PRIVATE_KEY>
PATH_TO_SRC=../src
PATH_TO_LIB=../lib

#
# Deploy Contracts
#

# TestERC20
forge_create | $PATH_TO_SRC/test/utils/TestERC20.sol:TestERC20 \
--constructor-args "TestERC20" "TEST" 18

# Registry
forge_create | $PATH_TO_SRC/core/Registry.sol:Registry

# Rate Model
forge_create | $PATH_TO_SRC/core/DefaultRateModel.sol:DefaultRateModel

# Risk Engine
forge_create | $PATH_TO_SRC/core/RiskEngine.sol:RiskEngine \
--constructor-args $REGISTRY

# Account Manager
forge_create | $PATH_TO_SRC/core/AccountManager.sol:AccountManager \
--constructor-args $REGISTRY

# Account
forge_create | $PATH_TO_SRC/core/Account.sol:Account

# Beacon
forge_create | $PATH_TO_SRC/proxy/Beacon.sol:Beacon \
--constructor-args $ACCOUNT

# Account Factory
forge_create | $PATH_TO_SRC/core/AccountFactory.sol:AccountFactory \
--constructor-args $BEACON

# LEther
forge_create | $PATH_TO_SRC/tokens/LEther.sol:LEther \
--constructor-args $REGISTRY 1

# LERC20
forge_create | $PATH_TO_SRC/tokens/LERC20.sol:LERC20 \
--constructor-args "LTestERC20" "LERC20" 18 $ERC20 $REGISTRY 1

# Oracle
forge_create | $PATH_TO_LIB/oracle/src/core/OracleFacade.sol:OracleFacade

# Controller
forge_create | $PATH_TO_LIB/controller/src/core/ControllerFacade.sol:ControllerFacade

#
# Register Contracts
#
registry_setAddress "ORACLE" $ORACLE
registry_setAddress "CONTROLLER" $CONTROLLER
registry_setAddress "RATE_MODEL" $RATE_MODEL
registry_setAddress "RISK_ENGINE" $RISK_ENGINE
registry_setAddress "ACCOUNT_FACTORY" $ACCOUNT_FACTORY
registry_setAddress "ACCOUNT_MANAGER" $ACCOUNT_MANAGER

#
# Set LTokens
#
registry_setLToken 0x0000000000000000000000000000000000000000 $LETH
registry_setLToken $ERC20 $LERC20

#
# Initialize
#
initialize $RISK_ENGINE
initialize $ACCOUNT_MANAGER
initialize $LETH
initialize $LERC20

#
# Helper Functions
#

forge_create () {
    forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY
}

string_to_bytes32 () {
    cast --from-utf8 $1 | cast --to-bytes32
}

cast_send () {
    cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $REGISTRY
}

registry_setAddress () {
    cast_send | "setAddress(bytes32, address)" $(string_to_bytes32 $1) $2
}

registry_setLToken () {
    cast_send | "setLToken(address, address)" $1 $2
}

initialize () {
    cast_send | "initialize()" $1
}