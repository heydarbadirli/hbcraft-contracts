<img src="https://dl.dropboxusercontent.com/scl/fi/82ct56ywcqdr1we6kjum4/ERC20StakingByHBCraft.png?rlkey=2ft8dmou99l36izwp2vcp6i3e&dl=0" alt="ERC20 Staking by HB Craft" align="right" width="200" height="200"/>

# ERC1155 Store with Dynamic Pricing by HB Craft
![version](https://img.shields.io/badge/version-1.0.0-blue)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

### Contract Introduction
The contract allows you to easily setup an ERC1155 store with dynamic pricing mechanism. Thanks to this contract you can list your assets priced in a `BASE_TOKEN` while letting the buyers to purchase them in a `QUOTE_TOKEN`. The listing prices are automatically converted and displayed in the `QUOTE_TOKEN`.

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

- **Enum `AccessTier`:** Defines the different access levels within the contract.
  ```solidity
  enum AccessTier { LISTER, TREASURY, OWNER }
  ```

| Name                          |  Tier  |
|:------------------------------|--------|
| `AccessTier.LISTER`           | **0**  |
| `AccessTier.TREASURY`         | **1**  |
| `AccessTier.OWNER`            | **2**  |


##### :warning: Important Points to Consider
- The `contractOwner` manages the store's overall functioning.
- But only the listers have the ability to create a listing, while `contractOwner` can also cancel a listing if needed.
- No matter which listing is purchased, the payment is always made to the `treasury.`
- By default, `contractOwner` and `treasury` are both set to the deployer address.
- Both `contractOwner` and `treasury` can be changed with the help of respective functions, so `treasury` can be set to a multi-sig wallet to protect the revenue while `contractOwner` freely manages the store.
- Only `treasury` can change the `treasury` address.
- Most functions are available only to the contract owner.


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


  "checkIfListingCompleted(uint256)": "10456d99",
  "checkIfListingValid(uint256,uint256)": "10bcfbd4",
  "checkListingQTPrice(uint256)": "0c9f9248",
  "checkMinimumPriceInBT()": "360dde4a",
  "checkRatePeriod()": "e46b7e03",
  "checkTotalListingCount()": "72f721a4",
  "contractOwner()": "ce606ee0",
  "convertBTPriceToQT(uint256)": "6ca2e10b",
  "convertToQT(uint256,bool)": "e40b42b4",
  "getActiveListingIDs()": "37bfd1d6",
  "getAllListingProperties()": "945bbe51",
  "getAllValidListings()": "40bfa17e",
  "getCurrentBTQTRate()": "a26be333",
  "getListing(uint256)": "107a274a",
  "getListingProperties(uint256)": "e0a03a51",
  "getListingQuantityLeft(uint256)": "f033668d",
  "getReferenceBTQTRate()": "f1255bec",
  "getValidListingIDs()": "2cc375a7",
  "isAutoPricingEnabled()": "f060b1e1",
  "isLister(address)": "fc0e8c1b",
  "lastBTQTRateLockTimestamp()": "9227f9e1",
  "lockedBTQTRate()": "9938221e",
  "minimumPriceInQT()": "c73c0a48",
  "purchase(uint256,uint256)": "70876c98",
  "rateLockDuration()": "3c6186a3",
  "rateSlippageTolerance()": "f674f07b",
  "removeLister(address)": "b07b5b69",
  "safePurchase(uint256,uint256,uint256)": "6a377cf4",
  "transferOwnership(address)": "f2fde38b",
  "treasury()": "61d027b3"