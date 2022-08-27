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

##### Ethereum mainnet

```bash
forge test --match-contract Integration --no-match-contract ArbiIntegration --fork-url https://rpc.ankr.com/eth
```

##### Arbitrum mainnet

```bash
forge test --match-contract ArbiIntegration --fork-url https://arb1.arbitrum.io/rpc -vvv
```

---

#### Configuring mappings

```bash
forge config > remappings.txt
```
