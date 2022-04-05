# Sentiment

## Instructions

Requirements:

1. Rust
2. Foundry - https://github.com/gakonst/foundry

Cloning Repo:

```bash
git clone --recurse-submodules git@github.com:sentimentxyz/protocol.git
```

Building Contracts:

```bash
forge build
```

Running tests:

```bash
forge test
```

Configuring with VSCode:
Create a remappings.txt and paste the mappings provided by `forge config`

Example:

```bash
controller/=lib/controller/src/
ds-test/=lib/ds-test/src/
oracle/=lib/oracle/src/
prb-math/=lib/prb-math/contracts/
solidity-bytes-utils/=lib/controller/lib/solidity-bytes-utils/contracts/
solmate/=lib/solmate/src/
```
