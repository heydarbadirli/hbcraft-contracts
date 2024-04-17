<img src="https://dl.dropboxusercontent.com/scl/fi/82ct56ywcqdr1we6kjum4/ERC20StakingByHBCraft.png?rlkey=2ft8dmou99l36izwp2vcp6i3e&dl=0" alt="ERC20 Staking by HB Craft" align="right" width="200" height="200"/>

# ERC1155 Store with Dynamic Pricing by HB Craft
![version](https://img.shields.io/badge/version-1.0.0-blue)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

### Contract Introduction
The contract lets you easily set up an ERC1155 store with a dynamic pricing mechanism. Thanks to this contract, you can list your assets priced in a `BASE_TOKEN` while allowing the buyers to purchase them in a `QUOTE_TOKEN`. The listing prices are automatically converted and displayed in the `QUOTE_TOKEN`.

---
### Key Features
#### 1. Oracle-less Price Updates
The value of the `QUOTE_TOKEN` for price conversion is calculated without the need for an external oracle or off-chain scripts to update the prices on-chain. The only thing the contract needs is a Uniswap pool featuring `BASE_TOKEN`/`QUOTE_TOKEN` pair to determine the rate by checking the `QUOTE_TOKEN` and `BASE_TOKEN` balance of the pool.

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
- Any purchase made during this period updates `lastCheckedBTQTRate` to transition to `NEW_LOCK` period after the `LOCK` period ends.

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
- If there is `rateSlippageTolerance` percent difference, then the current rate is rounded and the prices calculated with rounded current rate to ensure the stable pricing and not to get effected by the minor fluctuations.

<img src="https://dl.dropboxusercontent.com/scl/fi/mpfwgnuo1f0go91jx0cvq/Frame-18.png?rlkey=7ie0ctwx8guk405k93u82ufus&st=bbz66m95&dl=0" alt="Rate Periods" clear="left" width="675" height="398"/>

---
#### Access Control
The contract implements an access control system with distinct roles. Functionalities are restricted based on access levels. The system ensures that access to the execution of functions are strictly regulated.

**Enum `AccessTier`:** Different access levels within the contract.
  ```solidity
  enum AccessTier { LISTER, TREASURY, OWNER }
  ```


##### :warning: Important Points to Consider
- `contractOwner` manages the store's overall functioning.
- Only the listers have the ability to create a listing, while `contractOwner` can also cancel a listing if needed.
- No matter which listing is purchased, the payment is always made to the `treasury`.
- By default, `contractOwner` and `treasury` are both set to the deployer address.
- Both `contractOwner` and `treasury` can be changed by calling the respective functions, so `treasury` can be set to a multi-sig wallet to protect the revenue while `contractOwner` freely manages the store.
- Only `treasury` can change the `treasury` address.

Beside these, most functions are available only to `contractOwner` and you can find the complete list below:

| Function                   | Parameters                                                                        | Access Tier                 |
|----------------------------|-----------------------------------------------------------------------------------|-----------------------------|
| `changeTreasuryAddress`    | `address newTreasuryAddress`                                                      | **1**                       |
| `transferOwnership`        | `address newOwnerAddress`                                                         | **2**                       |
| `addLister`                | `address listerAddress`                                                           | **2**                       |
| `removeLister`             | `address listerAddress`                                                           | **2**                       |
| `setRateLockDuration`      | `uint256 durationInSeconds`                                                       | **2**                       |
| `setMinimumPriceInQT`      | `uint256 qtAmount`                                                                | **2**                       |
| `setRateSlippageTolerance` | `uint256 percent`                                                                 | **2**                       |
| `resetLockPeriod`          |                                                                                   | **2**                       |
| `setAutoPricingStatus`     | `bool isEnabled`                                                                  | **2**                       |
| `setBTQTRate`              |                                                                                   | **2**                       |
| `createListing`            | `address nftContractAddress` `uint256 nftID` `uint256 quantity` `uint256 btPrice` | **0**                       |
| `setListingBTPrice`        | `uint256 listingID` `uint256 btAmount`                                            | **2** and the listing owner |
| `purchase`                 | `uint256 listingID` `uint256 quantity`                                            | everyone                    |
| `safePurchase`             | `uint256 listingID` `uint256 quantity` `uint256 forMaxPriceInQT`                  | everyone                    |