<img src="https://dl.dropboxusercontent.com/scl/fi/82ct56ywcqdr1we6kjum4/ERC20StakingByHBCraft.png?rlkey=2ft8dmou99l36izwp2vcp6i3e&dl=0" alt="ERC20 Staking by HB Craft" align="right" width="200" height="200"/>

# ERC1155 Store with Dynamic Pricing by HB Craft
![version](https://img.shields.io/badge/version-1.0.0-blue)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

### Contract Introduction
The contract lets you easily set up an ERC1155 store with a dynamic pricing mechanism. Thanks to this contract, you can list your assets priced in a `BASE_TOKEN` while allowing the buyers to purchase them in a `QUOTE_TOKEN`. The listing prices are automatically converted and displayed in the `QUOTE_TOKEN`, no matter if there is decimal difference between `BASE_TOKEN` and `QUOTE_TOKEN`.

---
### Key Features
#### 1. Oracle-less Price Updates
The value of `QUOTE_TOKEN` for price conversion is calculated without the need for an external oracle or off-chain scripts to update `QUOTE_TOKEN` token value on-chain. The only thing the contract needs is a Uniswap pool featuring `BASE_TOKEN`/`QUOTE_TOKEN` pair to determine the rate by checking the `QUOTE_TOKEN` and `BASE_TOKEN` balances of the pool. It is enough to provide `dexPoolAddress` when `ERC1155Store` contract is deployed.

#### 2. Stable Pricing
The contract also features additional methods to ensure stable pricing under varying conditions. There are 3 distinct rate periods to manage price stability.

  ```solidity
  enum RatePeriod { LOCK, NEW_LOCK, FLOATING }
  ```

The price remains static during the `LOCK` and `NEW_LOCK` periods. The `LOCK` and `NEW_LOCK` periods last for `rateLockDuration`. The default value for the `rateLockDuration` is `15 minutes`, but it can be changed by calling the following command:

```solidity
function setRateLockDuration(uint256 durationInSeconds) external onlyContractOwner;
```

<img src="https://dl.dropboxusercontent.com/scl/fi/uee6ciquqmtdyb9h9xjw1/Frame-12.png?rlkey=1b66skrje253s845hzrogu420&st=mjis7i70&dl=0" alt="Rate Periods" clear="left" width="1070" height="352"/>


---
#### LOCK:
- Initially, upon deployment, the contract enters this period by calculating the `BASE_TOKEN`/`QUOTE_TOKEN` rate and updating `lockedBTQTRate` and `lastBTQTRateLockTimestamp`.
- This period lasts till `lastBTQTRateLockTimestamp` + `rateLockDuration`.
- Any purchase made during this period updates `lastCheckedBTQTRate` to transition to `NEW_LOCK` period after `LOCK` period ends.

<img src="https://dl.dropboxusercontent.com/scl/fi/bkzhvggwphs4i9hozoi7a/Frame-13.png?rlkey=xcgsam2mo7snykjoj3925gk2y&st=xl7dqn59&dl=0" alt="Rate Periods" clear="left" width="675" height="398"/>

#### NEW_LOCK:
A period imitating the next `LOCK` period. During this period, `lastCheckedBTQTRate` is used as the reference rate. If a purchase made during the `NEW_LOCK` period:
- `lastCheckedBTQTRate` assigned to the `lockedBTQTRate`.
- `lastCheckedBTQTRate` updated with the current rate.
- `lastBTQTRateLockTimestamp` + `rateLockDuration` assigned to the `lastBTQTRateLockTimestamp`
- Hence the contract transitions to `LOCK` period.

<img src="https://dl.dropboxusercontent.com/scl/fi/5on0l1sochmckbwoq2uqi/Frame-14.png?rlkey=bz9rc6apfhcczhsngv5mz5m7s&st=yjo5wums&dl=0" alt="Rate Periods" clear="left" width="675" height="398"/>

#### FLOATING:
- If no purchases are made during `LOCK` or `NEW_LOCK` periods, the contract enters this period.
- In this period, if current rate is not `rateSlippageTolerance` percent higher or lower than `lastCheckedBTQTRate`, then `lastCheckedBTQTRate` acts as a reference rate.
- If there is `rateSlippageTolerance` percent difference, then the current rate is rounded and the prices calculated with rounded current rate to ensure relatively stable pricing and not to get effected by the minor fluctuations.

`rateSlippageTolerance` is set to 3 percent by default, but it can be changed via following function:
```solidity
function setRateSlippageTolerance(uint256 percent) external onlyContractOwner;
```

<img src="https://dl.dropboxusercontent.com/scl/fi/mpfwgnuo1f0go91jx0cvq/Frame-18.png?rlkey=7ie0ctwx8guk405k93u82ufus&st=bbz66m95&dl=0" alt="Rate Periods" clear="left" width="675" height="398"/>

Nevertheless, it is also possible to disable the rate periods and just update the rate in intervals with off-chain scripts if needed. For disabling the rate period system:
```solidity
function setRatePeriodSystemStatus(bool isEnabled) external onlyContractOwner;
```

For updating the rate:
```solidity
function setBTQTRate() external onlyContractOwner;
```

If the contract is in FLOATING period for a while and you would like to switch back to `LOCK` period for a reason as if a purchase made, then following function can be called:
```solidity
function resetLockPeriod() external onlyContractOwner;
```


---
#### Access Control
The contract implements an access control system with distinct roles. Functionalities are restricted based on access levels. The system ensures that access to the execution of functions are strictly regulated.

**Enum `AccessTier`:** Different access levels within the contract.
  ```solidity
  enum AccessTier { LISTER, TREASURY, OWNER }
  ```


#### :warning: Important Points to Consider
**Contract Management**
- `contractOwner` manages the store's overall functioning.
- Only the listers have the ability to create a listing, while `contractOwner` can also cancel a listing if needed.
- No matter which listing is purchased, the payment is always made to the `treasury`.
- By default, `contractOwner` and `treasury` are both set to the deployer address.
- Both `contractOwner` and `treasury` can be changed by calling the respective functions (`transferOwnership` and `changeTreasuryAddress`), so `treasury` can be set to a multi-sig wallet to protect the revenue while `contractOwner` freely manages the store.
- Only `treasury` can change the `treasury` address.

**Listing**
The listing is considered invalid:
- If a lister revokes the approval for the contract.
- If a lister transfered their assets and now has less assets than listing quantity.
- If listing price in `QUOTE_TOKEN` is less than `minimumPriceInQT`, then it can not be listed. The current listings with price in `QUOTE_TOKEN` less than `minimumPriceInQT`is also invalid.

`minimumPriceInQT` is set to `1 * 10 ** QUOTE_TOKEN.decimals()`, but it can be changed via following functions:
```solidity
function setMinimumPriceInQT(uint256 qtAmount) external onlyContractOwner;
```

Most adminstrative functions are available only to `contractOwner` and you can find the complete list below:

| Function                   | Parameters                                                                        | Access Tier                 |
|----------------------------|-----------------------------------------------------------------------------------|-----------------------------|
| `addLister`                | `address listerAddress`                                                           | **2**                       |
| `cancelListing`            | `uint256 listingID`                                                               | **2** and the listing owner |
| `changeTreasuryAddress`    | `address newTreasuryAddress`                                                      | **1**                       |
| `createListing`            | `address nftContractAddress` `uint256 nftID` `uint256 quantity` `uint256 btPrice` | **0**                       |
| `purchase`                 | `uint256 listingID` `uint256 quantity`                                            | everyone                    |
| `removeLister`             | `address listerAddress`                                                           | **2**                       |
| `resetLockPeriod`          |                                                                                   | **2**                       |
| `safePurchase`             | `uint256 listingID` `uint256 quantity` `uint256 forMaxPriceInQT`                  | everyone                    |
| `setBTQTRate`              |                                                                                   | **2**                       |
| `setListingBTPrice`        | `uint256 listingID` `uint256 btAmount`                                            | **2** and the listing owner |
| `setMinimumPriceInQT`      | `uint256 qtAmount`                                                                | **2**                       |
| `setRateLockDuration`      | `uint256 durationInSeconds`                                                       | **2**                       |
| `setRatePeriodSystemStatus`| `bool isEnabled`                                                                  | **2**                       |
| `setRateSlippageTolerance` | `uint256 percent`                                                                 | **2**                       |
| `transferOwnership`        | `address newOwnerAddress`                                                         | **2**                       |


> *Note:* The difference between `purchase` and `safePurchase` functions is that since `safePurchase` requires the `uint256 forMaxPriceInQT` argument, in the scenario of the buyer approving more than the needed amount of tokens and the listing price suddenly going up right before the purchase, the purchase won't be processed but reverted.

---
### Read Functions
`getAllValidListings` function is the most usefull one when it comes to integrating the contract to your frontend. You can call the following functions to retrieve the other necessary data from the contract:

| Function                   | Parameters                                       |
|----------------------------|--------------------------------------------------|
| `checkIfListingCompleted`  | `uint256 listingID`                              |
| `checkIfListingValid`      | `uint256 listingID` `uint256 minimumPriceInBT`   |
| `checkListingQTPrice`      | `uint256 listingID`                              |
| `checkMinimumPriceInBT`    | `uint256 btPrice`                                |
| `checkRatePeriod`          |                                                  |
| `checkTotalListingCount`   |                                                  |
| `convertBTPriceToQT`       | `uint256 btPrice`                                |
| `convertToQT`              | `uint256 btAmount` `bool basedOnCurrentRate`     |
| `getActiveListingIDs`      |                                                  |
| `getAllListingProperties`  |                                                  |
| `getAllValidListings`      |                                                  |
| `getCurrentBTQTRate`       |                                                  |
| `getListing`               | `uint256 listingID`                              |
| `getListingProperties`     | `uint256 listingID`                              |
| `getListingQuantityLeft`   | `uint256 listingID`                              |
| `getReferenceBTQTRate`     |                                                  |
| `getValidListingIDs`       |                                                  |
| `isRatePeriodSystemEnabled`|                                                  |
| `isLister`                 | `address`                                        |

### Dependencies
This project uses the Foundry framework, the OpenZeppelin contracts (v5.0.1) and Uniswap V3 contracts (v1.0.0). You need to install necessary dependencies.

You can install the OpenZeppelin contracts and Uniswap V3 contracts by running:

```bash
$ forge install --no-commit OpenZeppelin/openzeppelin-contracts@v5.0.1
$ forge install --no-commit Uniswap/v3-core@v1.0.0
```

### Unit Test
The repository includes a series of unit test samples to cover a variety of scenarios. These tests serve as a starting point for the deployers to play with, expand, and adapt to their specific needs ensuring the smart contract perform as intended before deploying.

---
### License
This work is published under the brand name **HB Craft** and is licensed under the Apache License, Version 2.0 (the "License"); you may not use these files except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

You are authorized to use, modify, and distribute the work provided that appropriate credit is given to **HB Craft**, in any significant usage, you disclose the source of the work by providing a link to the original Apache License, and indicate if changes were made.

The work is distributed under the License on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.