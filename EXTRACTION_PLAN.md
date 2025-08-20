# Sentiment V1 Protocol Extraction Plan

## Overview
Extract all funds from deprecated Sentiment V1 protocol on Arbitrum to single recipient address.

## Control Structure  
- **ProxyAdmin**: `0x92f473Ef0Cd07080824F5e6B0859ac49b3AEb215`
- **ProxyAdmin Owner**: `0x3e5c63644E683549055b9be8653de26E0B4cd36e` 
- **Controls**: 7 LTokens + Registry + AccountManager + Beacon (all user accounts)

## Extraction Flow

### Phase 1: Upgrade Contracts
1. **Upgrade 7 LToken proxies** to `LTokenExtract` implementation
2. **Upgrade Beacon** to `AccountExtract` implementation

### Phase 2: Extract LToken Liquidity (~$23k)
Call `recoverFunds()` on each LToken:
- USDT: $634
- USDC: $1,241  
- FRAX: $7,416
- WETH: $13,196
- WBTC: $16
- ARB: $567
- OHM: $6

### Phase 3: Extract Account Collateral (~$65k)
Call `recoverFunds()` on each of the 4,800+ accounts.

## Key Functions

**LTokenExtract.recoverFunds()**
- Extracts available liquidity only (totalAssets - borrows)
- Emits `Recovered(asset, amount)` event

**AccountExtract.recoverFunds()** 
- Loops through account's assets array
- Transfers each token balance to multisig
- Emits `Recovered(position, owner, asset, amount)` event per asset

## Execution Script
Simple script that:
1. Calls `recoverFunds()` on 7 LTokens
2. Calls `recoverFunds()` on all accounts with assets
3. Handles batching for gas limits
4. Retries failed transactions

## User Claims
After recovery, users query Dune for their `Recovered` events by owner address to see what funds they can claim from the multisig.