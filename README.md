# UniSwap V2 

---

## 1. What is Uniswap V2?
> Uniswap V2 is a decentralized exchange protocol that lets anyone swap any ERC-20 token pair directly on-chain, using an automated market maker (AMM) instead of an order book. Prices are set by a constant-product formula, not by centralized intermediaries.  
[Read more](https://nansen.ai/post/what-is-uniswap-v2-architecture-pools-flash-swaps)

---

## 2. Order Book vs AMM
**Order book exchanges** match buyers and sellers, so you need someone on the other side of your trade. **AMMs** like Uniswap V2 use liquidity pools, so you always trade against a pool of tokens, and prices update automatically with each swap. For example, buying ETH with USDC on Uniswap means you interact with a pool, not a specific seller.  
[More details](https://docs.polkadot.com/smart-contracts/cookbook/eth-dapps/uniswap-v2/)

---


<img src = "./images/UniSwapV2-01.png">

## 3. UniswapV2ERC20 (LP token)
When you add liquidity to a Uniswap V2 pool, you get LP (liquidity provider) tokens. These represent your share of the pool. When you remove liquidity, your LP tokens are burned and you get your tokens back. Only the pair contract can mint or burn LP tokens—this prevents abuse and ensures the math stays correct.  
[Learn more](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) | [rareskills](https://rareskills.io/post/uniswap-v2-tutorial)

---

## 4. UniswapV2Pair
This is the smart contract that holds two ERC-20 tokens, tracks their reserves, and enforces the constant-product rule (x*y=k) for swaps. It also mints/burns LP tokens and charges a small fee on each swap. Keeping reserves in sync with actual balances is crucial—otherwise, attackers could exploit the pool.  
[More theory](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) | [rareskills](https://rareskills.io/post/uniswap-v2-tutorial)

---

## 5. UniswapV2Factory
The factory contract creates new pair contracts for each token pair and keeps a registry of all pairs. It ensures each pair is unique and uses CREATE2 for deterministic addresses. In production, you'd add more access control and state (like fee settings) to make it robust.  
[Binance blog](https://www.binance.com/en/square/post/18909021788401)

---

<img src = "./images/UniSwapV2-02.png">




