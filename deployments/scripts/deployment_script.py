import os
import subprocess
import sys

PRIVATE_KEY = ""
RPC_URL = ""


def get_deployment_address(output):
    count = 0
    i = 0
    address = ""
    while count < 2:
        if output[i] == ":":
            count += 1
        i += 1
    i += 1
    while output[i] != "\n":
        address += output[i]
        i += 1
    return address


def add_basic_commands(commands):
    commands += [
        "forge",
        "create",
        "--legacy",
        "--rpc-url",
        RPC_URL
    ]


def add_private_key(commands):
    commands += [
        "--private-key",
        PRIVATE_KEY
    ]


def add_args(commands, args=[]):
    if not args:
        return
    commands += ["--constructor-args"]
    for arg in args:
        if arg in contracts_data:
            commands.append(contracts_data[arg]['address'])
        else:
            commands.append(arg)


def add_src(contract, commands):
    commands += [contract["src"]]


def deploy(contract):
    commands = []
    add_basic_commands(commands)
    add_args(commands, contract["args"])
    add_private_key(commands)
    add_src(contract, commands)
    print(commands)
    os.chdir("../")
    output = subprocess.run(
        commands,
        stdout=subprocess.PIPE,
        text=True
    )
    contract["address"] = get_deployment_address(output.stdout)


contracts_data = {
    "RiskEngine": {
        "args": ["FeedAggregator"],
        "address": "0x3cfbf9cd019a8f936f56f69da81e6fcf3626b058",
        "src": "src/core/RiskEngine.sol:RiskEngine"
    },
    "UserRegistry": {
        "args": [],
        "address": "0x6db5119954d7626227476e3f5c6ff503258870d0",
        "src": "src/core/UserRegistry.sol:UserRegistry"
    },
    "DefaultRateModel": {
        "args": [],
        "address": "0x12b6687510d78c05ba6f3a421763934ca7784a11",
        "src": "src/core/DefaultRateModel.sol:DefaultRateModel"
    },
    "FeedAggregator": {
        "args": ["WETH"],
        "address": "0x8e9e2604b3e221ffbbe8c63048e89aa0c45e925d",
        "src": "src/priceFeeds/FeedAggregator.sol:FeedAggregator"
    },
    "Account": {
        "args": [],
        "address": "0xf8cfff57a017f588d8aecd5aacac9a6345612745",
        "src": "src/core/Account.sol:Account"
    },
    "Beacon": {
        "args": ["Account"],
        "address": "0x61ddaf7853a9e9183602db775a07aa18006ff97c",
        "src": "src/proxy/Beacon.sol:Beacon"
    },
    "AccountFactory": {
        "args": ["Beacon"],
        "address": "0xfaa4a292aaeb8c498dc1adb44afafee003f077d7",
        "src": "src/core/AccountFactory.sol:AccountFactory"
    },
    "AccountManager": {
        "args": ["RiskEngine", "AccountFactory", "UserRegistry"],
        "address": "",
        "src": "src/core/AccountManager.sol:AccountManager"
    },
    "WETH": {
        "address": "0xfaa4a292aaeb8c498dc1adb44afafee003f077d7"
    }
}


def deploy_contracts(contracts):
    for contract in contracts:
        deploy(contracts_data[contract])
    for contract in contracts:
        print(contracts_data[contract])


if __name__ == "__main__":
    RPC_URL = sys.argv[1]
    PRIVATE_KEY = sys.argv[2]
    contracts = sys.argv[3:]
    deploy_contracts(contracts)
