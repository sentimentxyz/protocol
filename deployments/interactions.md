# Sentiment Interactions

## Uniswap V3

| Interaction | Signature                                                                                                                                                    | Bytes      | Target                                     |
|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|--------------------------------------------|
| Swap        | multicall(bytes[] data)                                                                                                                                      | 0xac9650d8 | 0xE592427A0AEce92De3Edee1F18E0157C05861564 |
| Swap        | exactOutputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountOut, uint256 amountInMaximum, uint160 sqrtPriceLimitX96)) | 0x5023b4df | 0xE592427A0AEce92De3Edee1F18E0157C05861564 |
| Swap        | exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountIn, uint256 amountInMaximum, uint160 sqrtPriceLimitX96))   | 0x04e45aaf | 0xE592427A0AEce92De3Edee1F18E0157C05861564 |
| Unwrap      | unwrapWETH9(uint256 amount, address recipient)                                                                                                               | 0x49404b7c | 0xE592427A0AEce92De3Edee1F18E0157C05861564 |
| Refund      | refundETH()                                                                                                                                                  | 0x12210e8a | 0xE592427A0AEce92De3Edee1F18E0157C05861564 |

---

## Uniswap V2

| Interaction  | Signature                                                                                                                                                          | Bytes      | Target                                     |
|--------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|--------------------------------------------|
| Swap         | swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline)                                                     | 0x38ed1739 | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Swap         | swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] path, address to, uint256 deadline)                                                     | 0x8803dbee | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Swap         | swapExactETHForTokens(uint256 amountOutMin, address[] path , address to, uint256 deadline)                                                                         | 0x7ff36ab5 | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Swap         | swapETHForExactTokens(uint256 amountOut, address[] path, address to, uint256 deadline)                                                                             | 0xfb3bdb41 | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Swap         | swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline)                                                        | 0x18cbafe5 | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Swap         | swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] path, address to, uint256 deadline)                                                        | 0x4a25d94a | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Deposit      | addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAmin, uint256 amountBmin, address to, uint256 deadline) | 0xe8e33700 | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Withdraw     | removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAmin, uint256 amountBmin, address to, uint256 deadline)                           | 0xbaa2abde | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Deposit Eth  | addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountEthMin, address to, uint256 liquidity)                            | 0xf305d719 | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |
| Withdraw Eth | removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountEthMin, address to, uint256 deadline)                                   | 0x02751cec | 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 |

---

## Aave

| Interaction | Signature                                                                      | Bytes      | Target                                     |
|-------------|--------------------------------------------------------------------------------|------------|--------------------------------------------|
| Deposit     | supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) | 0x617ba037 | 0x794a61358D6845594F94dc1DB02A252b5b4814aD |
| Withdraw    | withdraw(address asset, uint256 amount, address to)                            | 0x69328dec | 0x794a61358D6845594F94dc1DB02A252b5b4814aD |
| DepositEth  | depositETH(address pool, address onBehalfOf, uint16 referralCode)              | 0x474cf53d | 0xC09e69E79106861dF5d289dA88349f10e2dc6b5C |
| WithdrawEth | withdrawETH(address pool, uint256 amount, address to)                          | 0x80500d20 | 0xC09e69E79106861dF5d289dA88349f10e2dc6b5C |

---

## WETH

| Interaction | Signature             | Bytes      | Target                                     |
|-------------|-----------------------|------------|--------------------------------------------|
| Wrap        | deposit()             | 0xd0e30db0 | 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1 |
| Unwrap      | withdraw(uint256 amt) | 0x2e1a7d4d | 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1 |

---

## Curve

| Interaction | Signature                                                                                   | Bytes      | Target                                     |
|-------------|---------------------------------------------------------------------------------------------|------------|--------------------------------------------|
| Swap        | exchange(uint256 tokenOutId, uint256 tokenInID, uint256 amount, uint256 amountOutMin, bool useEth) | 0x394747c5 | 0x960ea3e3C7FB317332d990873d354E18d7645590 |
| Deposit     | add_liquidity(uint256[3] amounts, uint256 amountOutMin)                                     | 0x4515cef3 | 0x960ea3e3C7FB317332d990873d354E18d7645590 |
| Withdraw    | remove_liquidity(uint256 amount, uint256[3] minAmounts)                                     | 0xecb586a5 | 0x960ea3e3C7FB317332d990873d354E18d7645590 |
| Withdraw    | remove_liquidity_one_coin(uint256 amount,uint256 coinId, uint256 amountOutMin)              | 0xf1dc3cc9 | 0x960ea3e3C7FB317332d990873d354E18d7645590 |

---

## Yearn

| Interaction | Signature                | Bytes      | Target                                     |
|-------------|--------------------------|------------|--------------------------------------------|
| Deposit     | deposit(uint256 amount)  | 0xb6b55f25 | 0x239e14A19DFF93a17339DCC444f74406C17f8E67 |
| Withdraw    | withdraw(uint256 amount) | 0x2e1a7d4d | 0x239e14A19DFF93a17339DCC444f74406C17f8E67 |
