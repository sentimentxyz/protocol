# Sentiment

## Instructions

### Requirements

1. Rust
2. Foundry - https://github.com/gakonst/foundry

---

### Cloning Repo

```bash
git clone --recurse-submodules git@github.com:sentimentxyz/protocol.git
```

---

### Building Contracts

```bash
forge build
```

---

### Running tests

#### Unit/Functional tests

```bash
forge test --no-match-contract Integration -vvv
```

#### Integration tests

```bash
forge test --match-contract Integration --fork-url https://rpc.ankr.com/eth -vvv
```

---

#### Configuring with VSCode

Create a remappings.txt and paste the mappings provided by `forge config`

Example:

```bash
controller/=lib/controller/src/
forge-std/=lib/forge-std/src/
oracle/=lib/oracle/src/
prb-math/=lib/prb-math/contracts/
solidity-bytes-utils/=lib/controller/lib/solidity-bytes-utils/contracts/
solmate/=lib/solmate/src/
```
