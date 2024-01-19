# ERC20 Staking V1.0 by HB Craft

## Overview
The contract allows the launching of a staking program and the creation of an unlimited number of staking pools inside the program, which can be either locked or flexible. All pools operate using a designated ERC20 token assigned during program deployment inside the constructor function.

## Supported Currencies
The contract was initially written for RMV token staking. However, it supports various ERC20 tokens with 18 decimals. Non-ERC20 tokens are not supported. Users stake earn interest in the token they have staked in.

## Features
- **Access Control:** The contract differentiates between various access levels: users (0), admins (1), and the contract owner (2), ensuring appropriate permissions and functionalities are assigned according to roles.

## Access Control
The contract implements an access control system with distinct roles to ensures that access to data and execution of functions are strictly regulated.

| Name                          | Value / Tier | Description                                                      |
|:------------------------------|:-------------|:-----------------------------------------------------------------|
| `AccessTier.USER`             | **0**        | Regular users with basic permissions.                            |
| `AccessTier.ADMIN`            | **1**        | Administrators with extended privileges for specific functions.  |
| `AccessTier.OWNER`            | **2**        | The contract owner with full control over all functions.         |

    - `USER` (0): Regular users with basic permissions.
    - `ADMIN` (1): Administrators with extended privileges for specific functions.
    - `OWNER` (2): The contract owner with full control over all functions.



## Custom Types
- **Enum `AccessTier`:** Defines the hierarchy of access levels within the contract.
  ```solidity
  enum AccessTier { USER, ADMIN, OWNER }

- **Enum `AccessTier`:** This enum defines the different access levels within the contract.
  ```solidity
  enum AccessTier { USER, ADMIN, OWNER }


## Administrative Controls
### Contract Owner
The contract owner can manage the program's overall functioning or configure staking pool properties individually. The functions listed below are available only to the contract owner to manage the program easily in regular conditions or emergencies.

| Function                          | Access Tier | Description |
|:----------------------------------|:------------|:------------|
| `launchDefault`                   | **2**       | Launches the staking program with two new staking pools, 1 locked, 1 flexible. |
| `pauseProgram`                    | **2**       | Pauses staking, withdrawal and interest claim activities for all pools. |
| `resumeProgram`                   | **2**       | Resumes the staking program with predefined settings.* |
| `endProgram`                      | **2**       | Ends the staking program, closes staking, opens withdrawal and interest claiming for all the pools and sets the program end date to the current timestamp. |

> *The predefined settings for the staking program are:
> 1. Both staking and interest claiming is open for locked and flexible pools.
> 2. Withdrawal is open for flexible pools, but closed for locked pools.


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

> **Note:** Both the `addContractAdmin`and the `removeContractAdmin` functions require a single parameter `userAddress` (variable type: `address`).


The following functions allow both the contract owner and contract administrators to change specific variables and properties:

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `changePoolAvailabilityStatus`    | **1**       | Changes the availability status of a specific staking pool. | `uint256 poolID, PoolDataType parameterToChange, bool valueToAssign` |
| `setPoolMiniumumDeposit`          | **1**       | Sets the minimum deposit amount for a specific pool.  | `uint256 poolID, uint256 newMinimumDepositAmount` |

## Fund Management
Contract owners and admins can collect and redeploy tokens staked in the pools if needed.

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `collectFunds`                    | **1**       | Collects staked funds from a specified pool.          | `uint256 poolID, uint256 etherAmount`   |
| `restoreFunds`                    | **1**       | Restores collected funds to a specified pool.         | `uint256 poolID, uint256 etherAmount`   |


Interests for all pools are sourced from a common interest pool. To enable stakers to claim interests, tokens must be transferred to the program's interest pool by the owner or admins. If necessary, tokens from the interest pool can be collected back by the admins or the owner.

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `provideInterest`                 | **1**       | Adds funds to the interest pool.                      | `uint256 etherAmount`                   |
| `collectInterestPoolFunds`        | **1**       | Collects funds from the interest pool.                | `uint256 etherAmount`                   |
