# ERC20 Staking v1.0 by HB Craft

## Introduction
The contract allows to launch a staking program and to create an unlimited number of staking pools inside the program, which can be either locked or flexible. All pools use the designated ERC20 token assigned during program deployment inside the `constructor` function.


### Key Features
**Multiple Staking Pools:**
- Ability to create numerous locked or flexible staking pools.

**Customizable Pool Properties:**
Each pool can have:
- Its minimum deposit and APY properties adjusted independently.
- Statuses (open or close) for staking, withdrawal, and interest claims controlled independently.

**Staking Target:**
- The program has a common staking target. When the total staked tokens across all pools reach this target, further staking is disabled, but the staking target can be adjusted if needed.


## Supported Tokens
The contract was initially written for RMV token staking. However, it supports various ERC20 tokens with 18 decimals. Non-ERC20 tokens are not supported. Users earn interest in the token they staked in.


## User Experience
**Staking:**
- Users can stake their tokens in various pools, each with distinct rules and rewards.
- Users have the flexibility to stake their tokens as many times as and in any amount (higher than the minimum deposit requirement) they wish in any created staking pool.
- Each time a user stakes in a pool, a unique deposit is created and added to the deposit list of the user within that specific staking pool with the staking date and the APY that the staking pool had at the time of staking. This means that the returns on each deposit are calculated based on the APY the pool had at the moment of staking.

#### :warning: Warning
- When a user interacts with the **program contract** for **staking**, **providing interest**, or **restoring funds**, please be aware that although the user initiates the transaction, the **program contract** technically carries out the expenditure. So, the user can get an **allowance too low** error, and the transaction can fail if the user doesn't interact with the **token contract** and approves the **program contract address** as a **spender** before interacting with the program contract.
- For this reason, before the user interacts with the program contract for these purposes, your application must take a crucial step to ensure that the user interacts with the **token contract** by calling the `increaseAllowance(spender, addedValue)` function of the **token contract**. This will allow the program contract to carry out the expenditure and ensure the smooth and proper functionality.


**Interest Claim:**
- Interest is calculated on a daily basis.
- Stakers have the option to claim their accrued interest daily. This provides flexibility and frequent access to earned interests.
- When interest is claimed, it is automatically calculated, collected from the common interest pool and sent to the staker if there are enough tokens in the interest pool.


 **Withdrawal:**
- When a staker decides to withdraw a deposit, the interest accrued on that deposit is also claimed simultaneously. The withdrawal action triggers both the withdrawal and the interest claim.


## Access Control
The contract implements an access control system with distinct roles. Functionalities are restricted based on access levels. The system ensures that access to data and execution of functions are strictly regulated.

- **Enum `AccessTier`:** Defines the different access levels within the contract.
  ```solidity
  enum AccessTier { USER, ADMIN, OWNER }
  ```

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
| `launchDefault`                   | **2**       | Launches the staking program with two new staking pools, 1 locked and 1 flexible. |
| `pauseProgram`                    | **2**       | Pauses staking, withdrawal, and interest claim activities for all pools. |
| `resumeProgram`                   | **2**       | Resumes the staking program with predefined settings.* |
| `endProgram`                      | **2**       | Ends the staking program, closes staking, opens the withdrawal and interest claiming for all the pools, and sets the program end date to the current timestamp. |

> *The `launchDefault` function requires a single parameter called `lockedAndFlexibleAPY`, which is an array of two uint256 values. The first number in this array represents the APY for the locked staking pool, while the second number indicates the APY for the flexible staking pool.

> **The predefined settings for the staking program are:
>  1. Both staking and interest claiming is open for locked and flexible pools.
>  2. Withdrawal is open for flexible pools, but closed for locked pools.


The functions listed below enable the contract owner to modify specific variables and properties of the contract:

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `setPoolAPY`                      | **2**       | Sets the Annual Percentage Yield (APY) for a specific pool. | `uint256 poolID` `uint256 newAPY`        |
| `setDefaultMinimumDeposit`        | **2**       | Sets the default minimum deposit amount.              | `uint256 newDefaultMinimumDeposit`      |
| `setStakingTarget`                | **2**       | Sets the staking target for the contract.             | `uint128 newStakingTarget`              |

> *Note:* When a new staking pool is created, it is added to the array of staking pools. Each pool has a unique identifier, called poolID. This ID is essentially the index of the pool within the array. The numbering for poolID starts from zero and increments sequentially with each new pool addition. This means the first pool created will have a poolID of 0, the second pool will have a poolID of 1, and so on.


### Contract Admins
The contract owner has the ability to assign contract admins, and they are also authorized to adjust individual pool parameters like minimum staking amount or pool status.

| Function                          | Access Tier | Description |
|:----------------------------------|:------------|:------------------------------------------------------|
| `addContractAdmin`                | **2**       | Adds a new admin to the contract. Requires that the input address is not the contract owner. |
| `removeContractAdmin`             | **2**       | Removes an existing admin. |

- **Note:** Both the `addContractAdmin`and the `removeContractAdmin` functions require a single parameter `userAddress` (variable type: `address`).


The following functions allow both the contract owner and contract administrators to change specific variables and properties:

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `changePoolAvailabilityStatus`    | **1**       | Changes the availability status of a specific staking pool. | `uint256 poolID` `PoolDataType parameterToChange` `bool valueToAssign` |
| `setPoolMiniumumDeposit`          | **1**       | Sets the minimum deposit amount for a specific pool.  | `uint256 poolID` `uint256 newMinimumDepositAmount` |


## Staking Fund Management
- Contract owners and admins can collect and restore the tokens staked in the pools if needed.

| Function                          | Access Tier | Description                                           | Parameters                              |
|:----------------------------------|:------------|:------------------------------------------------------|:----------------------------------------|
| `collectFunds`                    | **1**       | Collects staked funds from a specified pool.          | `uint256 poolID` `uint256 etherAmount`   |
| `restoreFunds`                    | **1**       | Restores collected funds to a specified pool.         | `uint256 poolID` `uint256 etherAmount`   |


## Interest Pool Management
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

| Function                             | AccessTier | Parameters                                                      | Returns        |
|:-------------------------------------|:-----------|:----------------------------------------------------------------|:---------------|
| `checkAPY`                           | **0**      | None                                                            | `uint256[]`    |
| `checkClaimableInterest`             | **0**      | `uint256 poolID` `address userAddress` `uint256 depositNumber`  | `uint256`    |
| `checkDefaultMinimumDeposit`         | **0**      | None                                                            | `uint256`      |
| `checkDepositCountOfAddress`         | **0**      | `address addressInput`                                          | `uint256[]`    |
| `checkIfInterestClaimOpen`           | **0**      | None                                                            | `bool[]`       |
| `checkIfStakingOpen`                 | **0**      | None                                                            | `bool[]`       |
| `checkIfWithdrawalOpen`              | **0**      | None                                                            | `bool[]`       |
| `checkInterestClaimedByAddress`      | **0**      | `address addressInput`                                          | `uint256[]`    |
| `checkPoolType`                      | **0**      | None                                                            | `PoolType[]`   |
| `checkStakedAmountByAddress`         | **0**      | `address addressInput`                                          | `uint256[]`    |
| `checkStakingTarget`                 | **0**      | None                                                            | `uint256`      |
| `checkTotalInterestClaimed`          | **0**      | None                                                            | `uint256[]`    |
| `checkTotalStaked`                   | **0**      | None                                                            | `uint256[]`    |
| `checkTotalWithdrew`                 | **0**      | None                                                            | `uint256[]`    |
| `checkWithdrewAmountByAddress`       | **0**      | `address addressInput`                                          | `uint256[]`    |
| `checkYourAccessTier`                | **0**      | None                                                            | `AccessTier`   |
| `checkCollectedFundsByAddress`       | **1**      | `address addressInput`                                          | `uint256[]`    |
| `checkInterestCollectedByAddress`    | **1**      | `address userAddress`                                           | `uint256`      |
| `checkInterestPool`                  | **1**      | None                                                            | `uint256`      |
| `checkInterestProvidedByAddress`     | **1**      | `address userAddress`                                           | `uint256`      |
| `checkTotalFundCollected`            | **1**      | None                                                            | `uint256[]`    |

- **Enum `PoolType`:** Defines the type of a staking pool.
  ```solidity
  enum PoolType { LOCKED, FLEXIBLE }
  ```

## :gear: Initial Configuration
Upon deployment of the `ERC20Staking` contract, the following parameters are set:

```solidity
constructor(){
        contractOwner = msg.sender;

        stakingToken = IERC20(`YOUR TOKEN CONTRACT ADDRESS`); // The address of the ERC20 token that will be used by program contract.
        stakingTarget = `YOUR TOKEN AMOUNT` ether; // This represents the contract's staking goal.

        defaultMinimumDeposit = `YOUR TOKEN AMOUNT` ether; // Used to determine staking pool properties when the program is launched with `launchDefault` function.
    }
```

After the contract is deployed:

- `defaultMinimumDeposit` and `stakingTarget` can be **adjusted** as needed to adapt to new staking strategies.
- `stakingToken` address is **fixed** upon deployment and cannot be changed later to ensure security and consistency.


## Dependencies
This project uses OpenZeppelin contracts for enhanced security and standardized features. If you are going to use a JavaScript-based development environment, such as Truffle or Hardhat, instead of Remix IDE for contract deployment, you might need to install necessary dependencies.

You can install the OpenZeppelin contracts by running:

```bash
npm install @openzeppelin/contracts
```

## License
Publishing my creative works under the brand name **HB Craft**.
The contract is released under the [CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/).
You are authorized to use, modify, and distribute, provided that appropriate credit to **HB Craft** is maintained.
