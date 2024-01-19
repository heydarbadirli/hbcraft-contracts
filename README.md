# ERC20 Staking v1.0 by HB Craft

## Overview
The contract allows the launching of a staking program and the creation of an unlimited number of staking pools inside the program, which can be either locked or flexible. All pools use the designated ERC20 token assigned during program deployment inside the constructor function.

### Key Features
- **Multiple Staking Pools:** Ability to create numerous staking pools in Locked and Flexible formats.
- **Staking Target:** The program has a common staking target. When the total staked tokens across all pools reach this target, further staking is disabled.
controllable statuses for staking, withdrawal, and interest claims.
- **Customizable Pool Properties:** Each pool can have its minimum deposit and APY settings adjusted and statuses for staking, withdrawal, and interest claims controlled independently.

## Supported Currencies
The contract was initially written for RMV token staking. However, it supports various ERC20 tokens with 18 decimals. Non-ERC20 tokens are not supported. Users earn interest in the token they have staked in.

## User Experience
**Staking:**
- Users can stake ERC20 tokens in various pools, each with distinct rules and rewards.
- Stakers have the flexibility to stake their tokens as many times as in any amount (higher than the minimum deposit requirement) they wish in the target staking pool.
- Each time a staker stakes in a pool, a unique deposit is created and added to the deposit list of the user within that specific staking pool with the staking date and the APY that the staking pool had at the time of staking. This means that the returns on each deposit are calculated based on the APY the pool had at the moment of staking.
**Interest Claim:**
- Interest on deposits is calculated on a daily basis. This ensures that the returns are updated daily, reflecting the staked tokens' most current valuation.
- Stakers have the option to claim their accrued interest daily. This provides flexibility and frequent access to earned interests.
- When interest is claimed, it is automatically calculated, collected from the common interest pool and sent to the staker if there are enough tokens in the interest pool.
**Withdrawal:**
- When a user decides to withdraw a deposit, the interest accrued on that deposit is also claimed simultaneously. The withdrawal action triggers the collection of both the principal deposit and the accrued interest. The total amount, comprising the original deposit and the interest earned, is then transferred to the user's account.

## Access Control
The contract implements an access control system with distinct roles. Functionalities are restricted based on access levels. The system ensures that access to data and execution of functions are strictly regulated.

- **Enum `AccessTier`:** Defines the different access levels within the contract.
  ```solidity
  enum AccessTier { USER, ADMIN, OWNER }

| Name                          | Value / Tier | Description                                                      |
|:------------------------------|:-------------|:-----------------------------------------------------------------|
| `AccessTier.USER`             | **0**        | Regular users with basic permissions.                            |
| `AccessTier.ADMIN`            | **1**        | Administrators with extended privileges for specific functions.  |
| `AccessTier.OWNER`            | **2**        | The contract owner with full control over all functions.         |


## Administrative Controls
### Contract Owner
The contract owner can manage the program's overall functioning or configure staking pool properties individually. The functions listed below are available only to the contract owner to manage the program easily in regular conditions or emergencies.

| Function                          | Access Tier | Description |
|:----------------------------------|:------------|:------------|
| `launchDefault`                   | **2**       | Launches the staking program with two new staking pools, 1 locked, 1 flexible. |
| `pauseProgram`                    | **2**       | Pauses staking, withdrawal and interest claim activities for all pools. |
| `resumeProgram`                   | **2**       | Resumes the staking program with predefined settings.* |
| `endProgram`                      | **2**       | Ends the staking program, closes staking, opens withdrawal and interest claiming for all the pools and sets the program end date to the current timestamp. |

  ```solidity
  *The predefined settings for the staking program are:
  1. Both staking and interest claiming is open for locked and flexible pools.
  2. Withdrawal is open for flexible pools, but closed for locked pools.


The functions listed below enable the contract owner to modify specific variables and properties of the contract:

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `setPoolAPY`                      | **2**       | Sets the Annual Percentage Yield (APY) for a specific pool. | `uint256 poolID, uint256 newAPY`        |
| `setDefaultMinimumDeposit`        | **2**       | Sets the default minimum deposit amount.              | `uint256 newDefaultMinimumDeposit`      |
| `setStakingTarget`                | **2**       | Sets the staking target for the contract.             | `uint128 newStakingTarget`              |

### Contract Admins
The contract owner has the ability to assign contract admins, and they are also authorized to adjust individual pool parameters like minimum staking amount, staking duration, and interest rates.

| Function                          | Access Tier | Description |
|:----------------------------------|:------------|:------------------------------------------------------|
| `addContractAdmin`                | **2**       | Adds a new admin to the contract. Requires that the input address is not the contract owner. |
| `removeContractAdmin`             | **2**       | Removes an existing admin. |

- **Note:** Both the `addContractAdmin`and the `removeContractAdmin` functions require a single parameter `userAddress` (variable type: `address`).


The following functions allow both the contract owner and contract administrators to change specific variables and properties:

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `changePoolAvailabilityStatus`    | **1**       | Changes the availability status of a specific staking pool. | `uint256 poolID, PoolDataType parameterToChange, bool valueToAssign` |
| `setPoolMiniumumDeposit`          | **1**       | Sets the minimum deposit amount for a specific pool.  | `uint256 poolID, uint256 newMinimumDepositAmount` |

## Fund Management
- Contract owners and admins can collect and redeploy tokens staked in the pools if needed.

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `collectFunds`                    | **1**       | Collects staked funds from a specified pool.          | `uint256 poolID, uint256 etherAmount`   |
| `restoreFunds`                    | **1**       | Restores collected funds to a specified pool.         | `uint256 poolID, uint256 etherAmount`   |


- Interests for all pools are sourced from a common interest pool.
- To enable stakers to claim interests, tokens must be transferred to the program's interest pool by the owner or admins.
- If necessary, tokens from the interest pool can be collected back by the admins or the owner.

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `provideInterest`                 | **1**       | Adds funds to the interest pool.                      | `uint256 etherAmount`                   |
| `collectInterestPoolFunds`        | **1**       | Collects funds from the interest pool.                | `uint256 etherAmount`                   |


## Data Collection and Access
- The program keeps detailed data of stakers, withdrawers, interest claimers, fund collectors, fund restorers, interest providers, and interest collectors in each pool.
- Information access is also tier-based, allowing for easy data retrieval depending on your access level.

| Function                             | Parameters                | Returns        | AccessTier |
|:-------------------------------------|:--------------------------|:---------------|:-----------|
| `checkAPY`                           | None                      | `uint256[]`    | **0**      |
| `checkDefaultMinimumDeposit`         | None                      | `uint256`      | **0**      |
| `checkDepositCountOfAddress`         | `address addressInput`    | `uint256[]`    | **0**      |
| `checkIfInterestClaimOpen`           | None                      | `bool[]`       | **0**      |
| `checkIfStakingOpen`                 | None                      | `bool[]`       | **0**      |
| `checkIfWithdrawalOpen`              | None                      | `bool[]`       | **0**      |
| `checkInterestClaimedByAddress`      | `address addressInput`    | `uint256[]`    | **0**      |
| `checkPoolType`                      | None                      | `PoolType[]`   | **0**      |
| `checkStakedAmountByAddress`         | `address addressInput`    | `uint256[]`    | **0**      |
| `checkStakingTarget`                 | None                      | `uint256`      | **0**      |
| `checkTotalInterestClaimed`          | None                      | `uint256[]`    | **0**      |
| `checkTotalStaked`                   | None                      | `uint256[]`    | **0**      |
| `checkTotalWithdrew`                 | None                      | `uint256[]`    | **0**      |
| `checkWithdrewAmountByAddress`       | `address addressInput`    | `uint256[]`    | **0**      |
| `checkYourAccessTier`                | None                      | `AccessTier`   | **0**      |
| `checkCollectedFundsByAddress`       | `address addressInput`    | `uint256[]`    | **1**      |
| `checkInterestCollectedByAddress`    | `address userAddress`     | `uint256`      | **1**      |
| `checkInterestPool`                  | None                      | `uint256`      | **1**      |
| `checkInterestProvidedByAddress`     | `address userAddress`     | `uint256`      | **1**      |
| `checkTotalFundCollected`            | None                      | `uint256[]`    | **1**      |
