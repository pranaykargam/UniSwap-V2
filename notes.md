
## 01.
` amountOut`  = (amountIn.997.reserveOut) /  (`reserveIn1000 + amountIn.997`)

## 02.
`Pool: 100 WETH / 200,000 USDC. You swap exactly 1 WETH in. Roughly how much USDC comes out`?

As a result, instead of getting $2,000$ USDC, you get roughly $1,974.3$ USDC.$6$ USDC of the loss went to the $0.3\%$ liquidity provider fee.

$\sim$ $19.7$ USDC of the loss was strictly due to price impact (the penalty of moving the pool's ratio by $1\%$).

## 03.

`Inside Pair.swap(), the invariant check is: balance0Adjusted · balance1Adjusted >= reserve0 · reserve1 · 1000². Why the 1000² factor`?

Because adjusted balances were scaled by 1000to apply the 3/1000 fee in integer math.

## 04.
`After a normal (non-flash) swap completes, what happens to k = reserve0·reserve1?`

it strictly increses, bcoz 0.3% fee stay with the reserves.

The 'constant' product is a floor, not an equality. The check is >=, and fees remain in the pool, so k grows with every trade. That growth is exactly what LPs earn — and what _mintFee measures via √k vs √kLast.

## 05.
`Where does slippage protection (amountOutMin) actually live`?
Router

## 06.
`Why are reserves stored as uint112 instead of uint256`?
gas: uint112 + uint112 + uint32 timestamp pack into a single storage slot.

## 07.

`When feeTo is set, the protocol fee is?`
Fees stay in the reserves; the protocol's cut is realized lazily. _mintFee compares √k to √kLast and mints LP to feeTo equal to 1/6 of the growth — economically ≈ 0.05% of volume (a sixth of 0.3%). No per-swap transfer, so swaps stay cheap.

## 08.

`skim` is the recovery valve for tokens sent directly to the pair (anyone can claim the excess — never 'pre-fund' a pair!). 

`sync` re-anchors reserves to balances, e.g. after a rebasing token contracts, or when balance > uint112 max has bricked _update.

## 09.🔴

`Why does the pair need the `lock` reentrancy modifier at all`?
During swap, tokens with hooks (ERC-777) or the flash-swap callback hand execution to arbitrary code while reserves are stale. Re-entering mint/burn/swap at that moment would use pre-trade reserves against post-trade balances. The single `unlocked` flag guards every state-mutating function.

## 10.🔴
`Standard swapExactTokensForTokens breaks with fee-on-transfer tokens. Why, and what's the correct variant`?

getAmountsOut assumes amountIn arrives in full; with FoT the pair receives less and the k-check reverts (or the user is overcharged). The SupportingFeeOnTransferTokens functions compute amountInput from balanceOf(pair) − reserve after transfer — the pair itself always worked this way; only the router's precomputation was wrong.

## 11 
`Why does the pair use a low-level call pattern (_safeTransfer) instead of plain IERC20.transfer`?

Tokens like USDT return no boolean; _safeTransfer accepts either no return data or an ABI-encoded true, so non-standard ERC-20s don't brick the pool


## 12🔴
`user's swap gets sandwiched. Which two router parameters are their only protection, and what does each stop`?
amountOutMin caps loss from price movement; deadline stops the tx being held and executed later at a worse price

