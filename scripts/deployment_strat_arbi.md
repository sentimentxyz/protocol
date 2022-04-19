# Deployment Strategy for Arb Mainnet

## Contract deployment flow

---

### Core Contracts

1. Registry
   1. Deploy implementation
   2. Deploy proxy
   3. Call init()
2. Account
   1. Deploy implementation
   2. Register account implementation against "ACCOUNT"
3. AccountManager
   1. Deploy implementation
   2. Deploy proxy
   3. Register account manager proxy against "ACCOUNT_MANAGER"
   4. Call init(Registry)
4. RiskEngine
   1. Deploy contract(Registry)
   2. Register risk engine against "RISK_ENGINE"
5. Beacon
   1. Deploy contract(Account)
   2. Register beacon against "ACCOUNT_BEACON"
6. AccountFactory
   1. Deploy contract(Beacon)
   2. Register account factory against "ACCOUNT_FACTORY"
7. RateModel
   1. Deploy Contract
   2. Register rate model factory against "RATE_MODEL"
8. OracleFacade
   1. Deploy Contract
   2. Register oracle against "ORACLE_FACADE"
9. ControllerFacade
   1. Deploy Contract
   2. Register controller against "CONTROLLER_FACADE"
10. Initializing dependencies
    1. AccountManager.initDep()
    2. RiskEngine.initDep()

---

### Lending Contracts

1. ETH
   1. Deploy LEther implementation
   2. Deploy Proxy(LEther)
   3. call init(WETH), "LEther", "LEth", IRegistry, reserveFactor)
   4. call Registry.setLToken(WETH, Proxy)
   5. call accountManager.toggleCollateralStatus(token)
   6. call Proxy.initDep()
2. ERC-20
   1. Deploy LToken implementation
   2. For Each token
      1. Deploy Proxy(LToken)
      2. call init(token, "LToken", "Token", IRegistry, reserveFactor)
      3. call Registry.setLToken(token, Proxy)
      4. call Proxy.initDep()
   3. Set collateral status for tokens
   4. [List of token addresses](deployment_strat_arbi.md/#arbitrum-token-addresses)

---

### Interactions

#### Chain link Oracle

1. Deploy ChainLinkOracle(ETH/USD)
    1. call oracleFacade.setOracle(token, ChainLinkOracle)
2. For every token call chainLinkOracle.setFeed(Token, Token/USD)

##### Chain link oracle Contracts

1. ETH/USD - 0x639fe6ab55c921f74e7fac1ee960c0b6293ba612
2. BTC/USD - 0x6ce185860a4963106506c203335a2910413708e9
3. STETH/USD - 0x07c5b924399cc23c24a95c8743de4006a32b7f2a
4. Other contracts are listed [here](https://data.chain.link/arbitrum/mainnet/crypto-usd)

---

#### Uniswap

1. Deploy Controllers
   1. Deploy UniV3Controller(controllerFacade)
   2. call controllerFacade.updateController(Router, UniV3Controller)
2. Toggle allowance for tokens which are to be swapped.
   1. controllerFacade.toggleTokenAllowance(token)

##### Uniswap Contracts

1. Router - 0xE592427A0AEce92De3Edee1F18E0157C05861564
2. Quoter - 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6
3. Router 2 -0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45

---

#### SushiSwap

1. Deploy Controller
   1. Deploy UniV2Controller(controllerFacade)
   2. call controllerFacade.updateController(SushiSwapRouter, UniV2Controller)
2. Deploy Oracle
   1. Deploy UniV2LPOracle(OracleFacade)
   2. call oracleFacade.setOracle(Pair, UniV2LPOracle)

##### SushiSwap Contracts

1. SushiSwap Router - 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
2. Factory - 0xc35DADB65012eC5796536bD9864eD8773aBc74C4
3. DPX/WETH - 0x0C1Cf6883efA1B496B01f654E247B9b419873054
4. WETH/USDC - 0x905dfCD5649217c42684f23958568e533C711Aa3
5. WETH/WBTC - 0x515e252b2b5c22b4b2b6Df66c2eBeeA871AA4d69
6. WETH/USDT - 0xCB0E5bFa72bBb4d16AB5aA0c60601c438F04b4ad
7. WETH/DAI - 0x692a0B300366D1042679397e40f3d2cb4b8F7D30

---

#### Aave

1. Deploy Controller
   1. Deploy AaveV3Controller(controllerFacade)
   2. Deploy AaveEthController(aWeth)
   3. call controllerFacade.updateController(Pool, aaveV3Controller)
   4. call controllerFacade.updateController(WETHGateway, AaveEthController)
2. Deploy Oracle
   1. deploy aTokenOracle(oracleFacade)
3. For each lending pool:
   1. call oracleFacade.setOracle(aToken, aTokenOracle)
   2. call controllerFacade.toggleTokenAllowance(aToken)

##### Aave contracts

1. Pool - 0x794a61358D6845594F94dc1DB02A252b5b4814aD
2. PoolDataProvider - 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
3. WETHGateway - 0xC09e69E79106861dF5d289dA88349f10e2dc6b5C
4. aWeth - 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8
5. aDai - 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE
6. aUSDC - 0x625E7708f30cA75bfd92586e17077590C60eb4cD
7. aUSDT - 0x6ab707Aca953eDAeFBc4fD23bA73294241490620
8. aWBTC - 0x078f358208685046a11C85e8ad32895DED33A249

---

#### WETH

1. Deploy Controller
   1. Deploy WETHController(WETH)
   2. call controllerFacade.updateController(WETH, WETHController)
   3. call controllerFacade.toggleTokenAllowance(WETH)
2. Deploy Oracle
   1. Deploy WETHOracle()
   2. call oracleFacade.setOracle(WETH, WETHOracle)

#### Curve

1. Deploy Controller
   1. Deploy CurveCryptoSwapController(controllerFacade)
   2. call controllerFacade.updateController(Pool, CurveCryptoSwapController)
2. Deploy Oracle
   1. Deploy CurveTriCryptoOracle(Pool)
   2. call oracleFacade.setOracle(crv3crypto, CurveTriCryptoOracle)

##### Curve Contracts

1. Pool - 0x960ea3e3C7FB317332d990873d354E18d7645590
2. crv3crypto - 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2

---

#### Yearn

1. Deploy Controller
   1. Deploy YearnVaultController()
   2. call controllerFacade.updateController(Curve3CryptoVault, YearnVaultController)
2. Deploy Oracle
   1. Deploy YTokenOracle(oracleFacade)
   2. call oracle.setOracle(Curve3CryptoVault, YTokenOracle)

##### Yearn Contracts

1. Curve3Crypto Vault - 0x239e14A19DFF93a17339DCC444f74406C17f8E67

---

### Arbitrum token addresses

1. WETH - 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
2. DAI - 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
3. USDC - 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
4. USDT - 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
5. WBTC - 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f
6. DPX - 0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55
7. RDPX - 0x32Eb7902D4134bf98A28b963D26de779AF92A212
8. GMX - 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a
