
# Contract Deployment

The _deployment_script_ can be used to deploy any contract.

## Requirements

Python3

## How to run the script

```bash
python deployment_script.py <RPC_URL> <Private_key> <contract 1> <contract 2> ...
```

## How to use the script

In order to deploy a contract or a series of contracts,
you will need to add the name of the contract to the contracts_data
object.

The object has three properties:

1. args: constructor args to deploy the contract. These args can be other contracts in the contracts_data or any constant data.
   1. If the arg is another contract, it will take the address of that contract and pass it as an argument.
2. address: address where the contract will be deployed or is already deployed.
3. src: destination of the contract.

## Output of the script

Will display the contract object of all the deployed contracts along.
