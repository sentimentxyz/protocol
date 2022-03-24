#!/bin/bash
set -e

RPC_URL=<RPC_URL>
PRIVATE_KEY=<PRIVATE_KEY>

# Since we use relative paths, cd into the script's directory before running it
PATH_TO_SRC=../src
PATH_TO_LIB=../lib

forge build --force # Compile everything

#
# Deploy Contracts
#

deploy() {
    if (($# > 1))
    then
        local path=$1
        shift
        { forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY $path \
        --constructor-args $@ | grep "Deployed to:" | cut -d" " -f3; } || exit $?
    else
        { forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY $1 \
        | grep "Deployed to:" | cut -d" " -f3; } || exit $?
    fi
}

ERC20=$(deploy ${PATH_TO_SRC}/test/utils/TestERC20.sol:TestERC20 \
    "TestERC20" "TEST" 18)
echo "ERC20: ${ERC20}"

REGISTRY=$(deploy ${PATH_TO_SRC}/core/Registry.sol:Registry)
echo "Registry: ${REGISTRY}"

RATE_MODEL=$(deploy ${PATH_TO_SRC}/core/DefaultRateModel.sol:DefaultRateModel)
echo "Rate Model: ${RATE_MODEL}"

RISK_ENGINE=$(deploy ${PATH_TO_SRC}/core/RiskEngine.sol:RiskEngine ${REGISTRY})
echo "Risk Engine: ${RISK_ENGINE}"

ACCOUNT_MANAGER=$(deploy ${PATH_TO_SRC}/core/AccountManager.sol:AccountManager \
    ${REGISTRY})
echo "Account Manager: ${ACCOUNT_MANAGER}"

ACCOUNT=$(deploy ${PATH_TO_SRC}/core/Account.sol:Account)
echo "Account: ${ACCOUNT}"

BEACON=$(deploy ${PATH_TO_SRC}/proxy/Beacon.sol:Beacon ${ACCOUNT})
echo "Beacon: ${BEACON}"

ACCOUNT_FACTORY=$(deploy ${PATH_TO_SRC}/core/AccountFactory.sol:AccountFactory \
    ${BEACON})
echo "Account Factory: ${ACCOUNT_FACTORY}"

LETHER=$(deploy ${PATH_TO_SRC}/tokens/LEther.sol:LEther ${REGISTRY} 1)
echo "LEther: ${LETHER}"

LERC20=$(deploy ${PATH_TO_SRC}/tokens/LERC20.sol:LERC20 \
    "LTestERC20" "LERC20" 18 ${ERC20} ${REGISTRY} 1)
echo "LERC20: ${LERC20}"

ORACLE=$(deploy ${PATH_TO_LIB}/oracle/src/core/OracleFacade.sol:OracleFacade)
echo "Oracle: ${ORACLE}"

CONTROLLER=$(deploy \ ${PATH_TO_LIB}/controller/src/core/ControllerFacade.sol:ControllerFacade)
echo "Controller: ${CONTROLLER}"

#
# Register Contracts
#

setAddress() {
    local registryKey
    registryKey=$(cast --from-utf8 $1 | cast --to-bytes32) || exit $?
    cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $REGISTRY \
    "setAddress(bytes32, address)" $registryKey $2
    echo "Successfully registered $2 as $1 with key ${registryKey}"
}

setAddress "ORACLE" $ORACLE
setAddress "CONTROLLER" $CONTROLLER
setAddress "RATE_MODEL" $RATE_MODEL
setAddress "RISK_ENGINE" $RISK_ENGINE
setAddress "ACCOUNT_FACTORY" $ACCOUNT_FACTORY
setAddress "ACCOUNT_MANAGER" $ACCOUNT_MANAGER

setLToken() {
    cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $REGISTRY \
    "setLToken(address, address)" $1 $2
    echo "Successfully set up LToken contract $2 for underlying token $1"
}

setLToken 0x0000000000000000000000000000000000000000 $LETHER
setLToken $ERC20 $LERC20

#
# Initialize Contracts
#

initialize() {
    cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $1 "initialize()"
    echo "Successfully Initialized $1"
}

initialize $RISK_ENGINE
initialize $ACCOUNT_MANAGER
initialize $LETHER
initialize $LERC20