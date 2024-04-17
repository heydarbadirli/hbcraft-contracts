# Dynamic Pricing Solidity Contract

## Overview

This Solidity contract offers a ERC1155 marketplace with dynamic pricing mechanism, without the need for an external oracle or offchain scripts to update prices on-chain. It automatically calculates the value of the quote token by checking the quote and base token balances of the Uniswap pool. The contract features additional methods to ensure stable pricing under varying market conditions.

## Features

- **Oracle-less Price Updates**: Calculates prices directly from Uniswap pool based on its base token and quote balances.
- **Three Rate Periods**: Utilizes three distinct rate periods (`LOCK`, `NEW_LOCK`, `FLOATING`) to manage price stability. The price remains static during the `LOCK` and `NEW_LOCK` periods.

### Rate Periods

**LOCK:**
- Initially, upon deployment, the contract enters this period by checking the quote token value and updating `lockedBTQTRate` and `lastBTQTRateLockTimestamp`.
- This period lasts till `lastBTQTRateLockTimestamp` + `rateLockDuration`.
- Any purchase made during this period updates `lastCheckedBTQTRate` to transition to the `NEW_LOCK` period after the `LOCK` period ends.

**NEW_LOCK:**
- A period imitating the next `LOCK` period.
- During this period, `lastCheckedBTQTRate` is used as the reference rate.
If a purchase made during the `NEW_LOCK` period:
- `lastCheckedBTQTRate` assigned to the `lockedBTQTRate`.
- `lastCheckedBTQTRate` updated with the current rate.
- `lastBTQTRateLockTimestamp` + `rateLockDuration` assigned to the `lastBTQTRateLockTimestamp`
- The contract transitions to `LOCK` period after the purchase.

**FLOATING:**
- If no purchases are made during `LOCK` or `NEW_LOCK` periods, the contract enters this period.
- In this period, if current rate is not `rateSlippageTolerance` percent higher or lower than `lastCheckedBTQTRate`, then `lastCheckedBTQTRate` acts as a reference rate. If there is `rateSlippageTolerance` percent difference, then the current rate is rounded and the prices calculated with rounded current rate to ensure the stable pricing and not to get effected by the minor fluctuations.