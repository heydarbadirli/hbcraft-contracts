/*
Copyright 2024 HB Craft

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.22;

import "@uniswap/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract StoreManager {
    address public immutable DEX_POOL_ADDRESS;

    IERC20Metadata internal immutable BASE_TOKEN;
    IERC20Metadata internal immutable QUOTE_TOKEN;

    uint256 internal immutable FIXED_POINT_PRECISION;
    uint256 internal immutable DECIMAL_POINT_ADJUSTMENT;

    enum DecimalCount {
        LESS,
        SAME,
        MORE
    }

    DecimalCount internal immutable btDecimalDifference;

    /// @dev Listing.btPricePerFraction is converted into QT for purchase calls and listing price checks
    struct Listing {
        address listerAddress;
        address nftContractAddress;
        uint256 nftID;
        uint256 quantity;
        uint256 btPricePerFraction;
        bool isActive;
    }

    Listing[] internal listings;
    uint256 internal activeListingStartIndex = 0;

    bool public isAutoPricingEnabled = true;

    enum RatePeriod {
        LOCK,
        NEW_LOCK,
        FLOATING
    }
    /**
     * @dev
     *     - When a purchased made, the BT/QT rate is locked for rateLockDuration if the rate is not locked yet
     *     - The default is rateLockDuration 15 minutes
     */

    uint256 public rateLockDuration;
    uint256 public lastBTQTRateLockTimestamp;
    uint256 public lockedBTQTRate;
    uint256 internal lastCheckedBTQTRate;
    uint256 public minimumPriceInQT;

    /**
     * @dev
     *     - The BT/QT rate is floating when the rate is not locked, and there is no lastCheckedBTQTRate to lock the rate
     *     - During RatePeriod.FLOATING lastCheckedBTQTRate taken as reference if current BT/QT rate doesn't have ± rateSlippageTolerance % difference to display stable listing prices
     *     - The default rateSlippageTolerance rate is 3%
     */
    uint256 public rateSlippageTolerance;

    constructor(address dexPoolAddress) {
        DEX_POOL_ADDRESS = dexPoolAddress;
        IUniswapV3Pool dexPool = IUniswapV3Pool(dexPoolAddress);

        BASE_TOKEN = IERC20Metadata(dexPool.token0());
        QUOTE_TOKEN = IERC20Metadata(dexPool.token1());

        uint256 btDecimals = uint256(BASE_TOKEN.decimals());
        uint256 qtDecimals = uint256(QUOTE_TOKEN.decimals());

        FIXED_POINT_PRECISION = 10 ** qtDecimals;

        if (btDecimals > qtDecimals) {
            DECIMAL_POINT_ADJUSTMENT = 10 ** (btDecimals - qtDecimals);
            btDecimalDifference = DecimalCount.MORE;
        } else if (btDecimals < qtDecimals) {
            DECIMAL_POINT_ADJUSTMENT = 10 ** (qtDecimals - btDecimals);
            btDecimalDifference = DecimalCount.LESS;
        } else {
            DECIMAL_POINT_ADJUSTMENT = 1;
            btDecimalDifference = DecimalCount.SAME;
        }

        rateLockDuration = 15 minutes;
        rateSlippageTolerance = 3;
        minimumPriceInQT = 1 * FIXED_POINT_PRECISION;
    }
}
