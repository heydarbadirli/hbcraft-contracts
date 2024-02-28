<img src="https://dl.dropboxusercontent.com/scl/fi/82ct56ywcqdr1we6kjum4/ERC20StakingByHBCraft.png?rlkey=2ft8dmou99l36izwp2vcp6i3e&dl=0" alt="ERC20 Staking by HB Craft" align="right" width="200" height="200"/>

# ERC20 Staking by HB Craft
![version](https://img.shields.io/badge/version-1.4.2-blue)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

- [What's New?](#whats-new)
    - [Version 1.4](#version-142---20240228)
    - [Version 1.3](#version-131---20240214)
    - [Version 1.2](#version-120---20240208)
    - [Version 1.1](#version-111---20240205)
- [Contract Introduction](#contract-introduction)
    - [Key Features](#key-features)
    - [Supported Tokens](#supported-tokens)
    - [User Experience](#user-experience)
    - [Access Control](#access-control)
    - [Administrative Controls](#administrative-controls)
    - [Data Collection and Retrieval](#data-collection-and-retrieval)
    - [Dependencies](#dependencies)
    - [License](#license)

---
### What's New?
### Version 1.4.2 - 2024/02/28
#### FIXED: `enoughFundsAvailable` and `ifTargetReached` BUGS
The latest update fixes a significant issue where deposits could get stuck due to an arithmetic error raised while calculating available funds if the total staked amount was less than the collected funds. The correction ensures that funds are accurately calculated, preventing deposits from being trapped.

---
### Version 1.4.1 - 2024/02/27
#### 1) ADDED: Zero Address Check
The check is added to the `transferOwnership` function to prevent accidentally losing control of the contract by setting the owner to an unowned address.

####  2) ADDED: `DepositDoesNotExist` error
Introduced to raise a custom error in such case.

####  3) IMPROVED: Gas Usage
Made several optimizations for gas usage.

---
### Version 1.4.0 - 2024/02/21
#### 1) FIXED: Interest Calculation on Withdrawn Deposits
The issue with withdrawn deposits still generating interest has been addressed. Interest calculation methods are fixed to return accurate values for withdrawn deposits. Now, a check ensures that only active deposits generate interest, preventing the interest pool from being depleted.

####  2) FIXED: State Update in `collectFunds` Function
The `collectFunds` function has been corrected to properly update the `totalList[DataType.FUNDS_COLLECTED]`

####  3) FIXED: `withdrawAll` Function Behavior
The function has been corrected to prevent failure when the last deposit is already withdrawn by relocating the modifiers.

####  4) ADDED: `InvalidArgumentValueCheck` error
Introduced to prevent setting default/pool minimum deposit and APY values to 0.

####  5) ADDED: `transferOwnership` Function
Made contract ownership transferable.

####  6) CHANGED: `contractAdmin` Privileges
Admin privileges are narrowed down to only restoring funds and providing interest to enhance security. This decision addresses the risk of a single malicious admin or compromised private key causing significant losses. Admin privileges might be increased within future versions with a multi-sig solution.

####  7) REMOVED: Some Read Functions
`checkCollectedFundsBy` and `checkInterestCollectedBy` functions are removed since only contractOwner can perform those actions in this version.

####  8) REMOVED: `userOnly` Modifier
The USER role is removed for being ineffective. It was initially intended to allow only users to stake tokens, excluding contract owner and admins. However, owner and admins could use alternate addresses for staking.

####  9) CHANGED: `checkDailyGeneratedInterest` Function
- Renamed to `checkGeneratedInterestDailyTotal`
- The `ifPrecise` argument is introduced to get around the error in passing the block limit after a certain point.
- If `true`, the function iterates over each staker's deposits to calculate the total daily interest.
- If `false`, it uses a simplified calculation based on the total staked amount and the pool's APY.

####  10) ADDED:  New Read Functions
- **`checkTotalClaimableInterestBy`**
- **`checkGeneratedInterestLastDayFor`**

####  11) IMPROVED: Gas Usage
Made several optimizations for gas usage.

---
### Version 1.3.1 - 2024/02/14
#### FIXED: Read Function BUG
The `checkDailyGeneratedInterest` function now doesn't consider deposits that have already withdrawn, hence gives more precise calculations on total expected interest to be generated.

---
### Version 1.3.0 - 2024/02/13
#### 1) CHANGED: Decimal Support for All Functions
All contract functions have been updated to work with decimal values only (token units). This change requires both input arguments to include decimals and returns output values with decimals, aligning with the standards of other blockchain contracts. This adjustment was made to prioritize compliance over simplicity. The update aims to reduce confusion and simplify integration for developers working with multiple libraries.

#### 2) ADDED: New Read Functions
- **`checkTotalClaimableInterestBy`:** Returns the total claimable interest for an address in a pool. It simplifies the frontend display of total claimable interest for users, removing the need to iterate individual deposits with the `checkClaimableInterestBy` function.
- **`checkDepositStakedAmount`:** Returns the token amount deposited by a user in a single transaction.
- **`checkTotalClaimableInterest`:** Returns the total interest accrued and claimable by all users in a pool, aiding in the management of interest payouts and avoiding errors related to insufficient funds in the interest pool beforehand.
- **`checkDailyGeneratedInterest`:** Calculates and returns the total expected interest to be generated in a pool in a day based on the current staked token amount, facilitating better planning of interest allocations.

#### 3) ADDED: `onlyUser` Modifier
A new modifier has been implemented to restrict staking actions to users only, excluding `contractOwner` and `contractAdmin`s. This addition closes potential loopholes that could allow for the cyclic exploitation of fund collection and staking processes.

---
### Version 1.2.0 - 2024/02/08
#### 1) REMOVED: 2 Global Variables
The `stakingTarget` and `programEndDate` variables have been eliminated to introduce a more dynamic staking pool management approach. This change supports a flexible structure, allowing for tailored management of each staking pool.

#### 2) ADDED: New StakingPool Properties
The `stakingTarget` and `endDate` properties are introduced to the `StakingPool` struct. This enhancement enables the specification of unique staking targets and end dates for each pool, facilitating the independent operation of multiple staking pools. This flexibility allows for the addition and conclusion of pools with varied staking targets without the need for deploying new contracts.

#### 3) CHANGED: Staking Pool Addition Mechanism
- The previous `launchDefault` function has been deprecated in favor of the `addStakingPoolDefault` function, which now supports the addition of either a locked or flexible pool with default settings instead of adding 2 pools (1 locked and 1 flexible) in one go.
- The `addStakingPool` function has been renamed to `addStakingPoolCustom` and revised to allow for the addition of pools with more customizable properties.

#### 4) REMOVED: Access Control for Read Functions
The update is made to improve user experience across diverse platforms.

Initially, the contract included access control checks for read functions to manage who could retrieve which information. However, this approach led to unintended complications, particularly when using platforms like **PolygonScan** and **MyEtherWallet**.

The issue stemmed from how these platforms execute read function calls. Unlike the **Remix IDE** or frameworks like **Foundry**, which use the caller's address to call the read functions, these platforms don't use the caller's address when they cast a read call. This difference causes the contract to revert calls due to access control checks, leading to errors in one tool but not in another, which can confuse the deployers and the developers.

For example, **PolygonScan** would error out read functions (with access controls) requiring inputs while returning default type values for those without inputs.

**MyEtherWallet**, on the other hand, consistently reverted all read function calls with access controls. This inconsistency could mislead developers into misinterpreting the contract's behavior and further complicating diagnostics and user experience.

After careful consideration and recognizing that all blockchain data is publicly available and can be scrapped quite easily, I have concluded that strict access controls on read functions are unnecessary and removed the feature from the contract. Future updates may reintroduce access control for the read functions as an extension.

#### 5) CHANGED: Read Functions
The addition of new properties to staking pools necessitated the modification of the read functions.

- Read functions have been updated to return a single value based on the `poolID`
- `checkStakingTarget` and `checkMinimumDeposit` functions is now used for retrieving StakingPool property values

#### 6) CHANGED: The `endProgram` function
The endProgram function has been renamed to endStakingPool and the `ifPoolEnded` is introduced to enforce the immutability of concluded pools by preventing further modifications.
- The stakers in finalized pools can still withdraw their stakes and claim their interest.

#### 7) ADDED: Confirmation Code
- A confirmation code is now mandated for invoking the `endStakingPool` function to prevent ending a `StakingPool` accidentally.
- This code is set during the program's deployment phase.

#### 8) ADDED: New Events
A series of new events are added to improve the ease of tracking program updates and changes. Here is the full list of newly added events:
- `CreateProgram`
- `PauseProgram`
- `ResumeProgram`

- `AddContractAdmin`
- `RemoveContractAdmin`

- `AddStakingPool`
- `EndStakingPool`

- `UpdateDefaultStakingTarget`
- `UpdateDefaultMinimumDeposit`

- `UpdateStakingTarget`
- `UpdateMinimumDeposit`

- `UpdateStakingStatus`
- `UpdateWithdrawalStatus`
- `UpdateInterestClaimStatus`

#### 9) IMPROVED: Expanded Unit Testing
- Unit tests have been broadened to align with the latest updates, ensuring comprehensive validation of the modified functionalities.
- The `InterestManagementScenarios.t.sol` file name is changed to `MainManagementScenarios.t.sol` to better reflect the comprehensive testing of main management scenarios.

#### 10) CHANGED: Enum Type as an Input/Output
Custom enum types as a function argument or return type have been converted to uint256 to ensure compatibility across different software interfaces.

For the `uint256 parameterToChange` argument the numbers represent:
  ```bash
  0 - isStakingOpen
  1 - isWithdrawalOpen
  2 - isInterestClaimOpen
  ```

---
### Version 1.1.1 - 2024/02/05
#### FIXED: Automatic Interest Claim
With this update, when users initiate a deposit withdrawal, the program also automatically sends the accumulated interest for that deposit to the user. However, when the interest claim from the staking pool is disabled, the program will default to withdrawing only the deposited amount, bypassing the interest claim.

---
### Version 1.1.0 - 2024/02/02
#### 1) ADDED: Foundry Integration
The integration is introduced for seamless smart contract deployment. Now, deploying your contract is as straightforward as running the following command:

  ```bash
  cast wallet import <YOUR_WALLET_NAME> --private-key <YOUR_PRIVATE_KEY>
  forge create src/ERC20Staking.sol:ERC20Staking --constructor-args <YOUR_TOKEN_CONTRACT_ADDRESS> <DEFAULT_STAKING_TARGET> <DEFAULT_MINIMUM_DEPOSIT> <YOUR_CONFIRMATION_CODE> --account <YOUR_WALLET_NAME> --rpc-url <YOUR_RPC_URL>
  ```
##### Before You Deploy
Customize the following variables in the `src/ERC20Staking.sol` file according to your project's needs before deploying:

- `_defaultMinimumDeposit` and `_defaultStakingTarget` can be **adjusted** later if needed to adapt to new staking strategies.
- `stakingToken` address is **fixed** upon deployment and cannot be changed later to ensure security and consistency.

#### 2) ADDED: Unit Test Samples
Alongside the Foundry integration, a series of unit test samples are designed and introduced to cover a variety of scenarios. These tests serve as a starting point for the deployers to play with, expand, and adapt to their specific needs ensuring the smart contract perform as intended before deploying.

Here's a glimpse of the test scenarios now available:

**Main Scenarios**
- StakingScenarios.t.sol: Examine various staking conditions and behaviors.
- WithdrawalScenarios.t.sol: Validate the withdrawal process and its edge cases.
- InterestClaimScenarios.t.sol: Test the claiming process of interest within the staking program.

**Management Scenarios**
- AccessControlScenarios.t.sol: Assure that access controls are correctly enforced.
- InterestManagementScenarios.t.sol: Ensure the accurate management of interest rates and distribution.

#### 3) ADDED: Personal Data Access
A notable feature of our updated access control is the implementation of `personalDataAccess`. This allows users to securely access their own data while maintaining strict privacy controls.

#### 4) ADDED: Expanded Token Compatibility
With this update, The program's flexibility to use a broader range of ERC20 tokens is expanded. Previously, deployers were limited to use only ERC20 tokens with 18 decimals. Now, this restriction is removed, enabling the use of any ERC20 token as a staking token, regardless of its decimal specification.

#### 5) IMPROVED: General Improvements
With this version, increased withdrawal validation measures are implemented to resolve issues that could arise in specific scenarios. E.g not being able to withdraw other deposits after a double withdrawal attempt from a single deposit. Additionally, the improvements are made to the interest calculation mechanism.

---
### Contract Introduction
The contract allows to launch a staking program and to create an unlimited number of staking pools inside the program, which can be either locked or flexible. All pools use the designated ERC20 token assigned during program deployment inside the `constructor` function.

---
### Key Features
**Multiple Staking Pools:**
- Ability to create numerous locked or flexible staking pools.

- **Enum `PoolType`:** Defines the type of a `StakingPool`.
  ```solidity
  enum PoolType { LOCKED, FLEXIBLE }
  ```

**Customizable Pool Properties:**
Each pool can have:

- `stakingTarget`
- `minimumDeposit`
- `APY`
- Statuses (open or close) for staking, withdrawal, and interest claims controlled independently.

---
### Supported Tokens
The contract was initially written for RMV token staking. However, it supports all ERC20 tokens. Non-ERC20 tokens are not supported. Users earn interest in the token they staked in.

---
### User Experience
**Staking:**
- Users can stake their tokens in various pools, each with distinct rules and rewards.
- Users have the flexibility to stake their tokens as many times as and in any amount they wish in any created staking pool.
- Each time a user stakes in a pool, a unique deposit is created and added to the deposit list of the user within that specific staking pool with the staking date and the APY that the staking pool had at the time of staking. This means that the returns on each deposit are calculated based on the APY the pool had at the moment of staking.

##### :warning: Warning
- When a user interacts with the **program contract** for **staking**, **providing interest**, or **restoring funds**, please be aware that although the user initiates the transaction, the **program contract** technically carries out the expenditure. So, the user can get an **allowance too low** error, and the transaction can fail if the user doesn't interact with the **token contract** and approves the **program contract address** as a **spender** before interacting with the program contract.
- For this reason, before the user interacts with the program contract for these purposes, your application must take a crucial step to ensure that the user interacts with the **token contract** by calling the `increaseAllowance(spender, addedValue)` function of the **token contract**. This will allow the program contract to carry out the expenditure and ensure the smooth and proper functionality.


**Interest Claim:**
- Interest is calculated on a daily basis.
- Stakers have the option to claim their accrued interest daily. This provides flexibility and frequent access to earned interests.
- When interest is claimed, it is automatically calculated, collected from the common interest pool and sent to the staker if there are enough tokens in the interest pool.


 **Withdrawal:**
- When a staker decides to withdraw a deposit, the interest accrued on that deposit is also claimed simultaneously if the interest claim is open for that pool.

---
### Access Control
The contract implements an access control system with distinct roles. Functionalities are restricted based on access levels. The system ensures that access to the execution of functions are strictly regulated.

- **Enum `AccessTier`:** Defines the different access levels within the contract.
  ```solidity
  enum AccessTier { ADMIN, OWNER }
  ```

| Name                          | Value / Tier | Description                                                                                       |
|:------------------------------|:-------------|:--------------------------------------------------------------------------------------------------|
| `AccessTier.ADMIN`            | **1**        | Administrators with extended privileges for specific functions.                                   |
| `AccessTier.OWNER`            | **2**        | The contract owner with full control over all functions.                                          |

---
### Administrative Controls
The `contractOwner` can manage the program's overall functioning or configure staking pool properties individually. The `contractOwner` has the ability to assign `contractAdmin`s, and they are also authorized to partially participate in the program management. Most functions are available only to the contract owner.

| Function                          | Parameters                                                                                                     | Access Tier      | Description                                                                                                  |
|-----------------------------------|-----------------------------------------------------------------------------------------------------------------|------------------|--------------------------------------------------------------------------------------------------------------|
| `addContractAdmin`                | `address userAddress`                                                                                           | `onlyContractOwner` | Adds a new contract admin.                                                                           |
| `addStakingPoolDefault`           | `uint256 typeToSet` `uint256 APYToSet`                                                                           | `onlyContractOwner` | Adds a new staking pool with default settings.                                                                       |
| `addStakingPoolCustom`           | `uint256 typeToSet` `uint256 stakingTargetToSet` `uint256 minimumDepositToSet` `bool stakingAvailabilityStatus` `uint256 APYToSet`                                                                           | `onlyContractOwner` | Adds a new staking pool with custom properties.                                                                       |
| `changePoolAvailabilityStatus`    | `uint256 poolID` `uint256 parameterToChange` `bool valueToAssign`                                                 | `onlyContractOwner`        | Modifies availability status of a staking pool.                                                                     |
| `collectFunds`                    | `uint256 poolID` `uint256 tokenAmount`                                                                           | `onlyContractOwner`        | Collects staked funds from a staking pool.                                                                           |
| `collectInterestPoolFunds`        | `uint256 tokenAmount`                                                                                           | `onlyContractOwner`        | Collects funds from the interest pool.                                                                       |
| `endStakingPool`                  | `uint256 poolID `uint256 _confirmationCode`                                                                     | `onlyContractOwner` | Ends a specified staking pool.                                                                               |
| `pauseProgram`                    | None                                                                                                            | `onlyContractOwner` | Closes staking, withdrawal and interest claim for all the pools.                                                                               |
| `provideInterest`                 | `uint256 tokenAmount`                                                                                           | `onlyAdmins`        | Adds funds to the interest pool.                                                                             |
| `removeContractAdmin`             | `address userAddress`                                                                                           | `onlyContractOwner` | Removes a contract admin.                                                                            |
| `resumeProgram`                   | None                                                                                                            | `onlyContractOwner` | Sets availability status of the staking pools back to predefined settings.                                                         |
| `restoreFunds`                    | `uint256 poolID` `uint256 tokenAmount`                                                                           | `onlyAdmins`        | Restores collected funds back to a staking pool.                                                                     |
| `setDefaultMinimumDeposit`        | `uint256 newDefaultMinimumDeposit`                                                                              | `onlyContractOwner` | Sets the program default minimum deposit.                                                              |
| `setDefaultStakingTarget`         | `uint256 newStakingTarget`                                                                                      | `onlyContractOwner` | Sets the program default staking target.                                                               |
| `setPoolAPY`                      | `uint256 poolID` `uint256 newAPY`                                                                                | `onlyContractOwner` | Sets a new APY for a specified staking pool.                                                                         |
| `setPoolMiniumumDeposit`          | `uint256 poolID` `uint256 newMinimumDeposit`                                                                     | `onlyAdmins`        | Sets a new minimum deposit for a staking pool.                                                                       |
| `setPoolStakingTarget`            | `uint256 poolID` `uint256 newStakingTarget`                                                                      | `onlyContractOwner` | Sets a new staking target for a staking pool.                                                                        |

> The predefined settings for the staking program are:
>  1. Both staking and interest claiming is open for locked and flexible pools.
>  2. Withdrawal is open for flexible pools, but closed for locked pools.

> *Note:* When a new staking pool is created, it is added to the array of staking pools. Each pool has a unique identifier, called poolID. This ID is essentially the index of the pool within the array. The numbering for poolID starts from zero and increments sequentially with each new pool addition. This means the first pool created will have a poolID of 0, the second pool will have a poolID of 1, and so on.

---
### Data Collection and Retrieval
The program keeps detailed data of stakers, withdrawers, interest claimers, fund collectors, fund restorers, interest providers, and interest collectors in each pool and provides a set of read functions for easy data retrieval.

| Function   | Parameters                                                                                                 |
|------------|------------------------------------------------------------------------------------------------------------|
| `checkAPY`                         | `uint256 poolID`                                                                   |
| `checkClaimableInterestBy`         | `address userAddress` `uint256 poolID` `uint256 depositNumber` `bool withDecimals` |
| `checkConfirmationCode`            | None                                                                               |
| `checkDailyGeneratedInterest`      | `uint256 poolID`                                                                   |
| `checkDefaultMinimumDeposit`       | None                                                                               |
| `checkDefaultStakingTarget`        | None                                                                               |
| `checkDepositCountOfAddress`       | `address userAddress` `uint256 poolID`                                             |
| `checkDepositStakedAmount`         | `address userAddress` `uint256 poolID` `uint256 depositNumber`                     |
| `checkEndDate`                     | `uint256 poolID`                                                                   |
| `checkGeneratedInterestDailyTotal` | `uint256 poolID` `ifPrecise`                                                       |
| `checkGeneratedInterestLastDayFor` | `address userAddress` `uint256 poolID`                                             |
| `checkIfInterestClaimOpen`         | `uint256 poolID`                                                                   |
| `checkIfPoolEnded`                 | `uint256 poolID`                                                                   |
| `checkIfStakingOpen`               | `uint256 poolID`                                                                   |
| `checkIfWithdrawalOpen`            | `uint256 poolID`                                                                   |
| `checkInterestClaimedBy`           | `address userAddress` `uint256 poolID`                                             |
| `checkInterestPool`                | None                                                                               |
| `checkInterestProvidedBy`          | `address userAddress`                                                              |
| `checkMinimumDeposit`              | `uint256 poolID`                                                                   |
| `checkPoolCount`                   | None                                                                               |
| `checkPoolType`                    | `uint256 poolID`                                                                   |
| `checkRestoredFundsBy`             | `address userAddress` `uint256 poolID`                                             |
| `checkStakedAmountBy`              | `address userAddress` `uint256 poolID`                                             |
| `checkStakingTarget`               | `uint256 poolID`                                                                   |
| `checkTotalClaimableInterest`      | `uint256 poolID`                                                                   |
| `checkTotalClaimableInterestBy`    | `address userAddress` `uint256 poolID`                                             |
| `checkTotalFundCollected`          | `uint256 poolID`                                                                   |
| `checkTotalFundRestored`           | `uint256 poolID`                                                                   |
| `checkTotalInterestClaimed`        | `uint256 poolID`                                                                   |
| `checkTotalStaked`                 | `uint256 poolID`                                                                   |
| `checkTotalWithdrawn`              | `uint256 poolID`                                                                   |
| `checkWithdrawnAmountBy`           | `address userAddress` `uint256 poolID`                                             |

---
### Dependencies
This project uses the Foundry framework with the OpenZeppelin contracts (v5.0.1) for enhanced security and standardized features. You need to install necessary dependencies.

You can install the OpenZeppelin contracts by running:

```bash
$ forge install --no-commit OpenZeppelin/openzeppelin-contracts@v5.0.1
```

---
### License
This work is published under the brand name **HB Craft** and is licensed under the Apache License, Version 2.0 (the "License"); you may not use these files except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

You are authorized to use, modify, and distribute the work provided that appropriate credit is given to **HB Craft**, in any significant usage, you disclose the source of the work by providing a link to the original Apache License, and indicate if changes were made.

The work is distributed under the License on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
