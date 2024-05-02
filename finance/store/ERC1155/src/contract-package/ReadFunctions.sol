// SPDX-License-Identifier: GPL-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "../safety-package/AccessControl.sol";
import "../pricing-package/MathFunctions.sol";
import "../pricing-package/UniswapOracle.sol";

abstract contract ReadFunctions is AccessControl, MathFunctions, UniswapOracle {
    // ======================================
    // =         Listing Related            =
    // ======================================
    function checkTotalListingCount() external view returns (uint256) {
        return listings.length;
    }

    function checkIfListingSoldOut(uint256 listingID) external view returns (bool) {
        if (listings[listingID].quantity == 0) return true;
        else return false;
    }

    function getListingProperties(uint256 listingID)
        external
        view
        returns (address, address, uint256, uint256, uint256)
    {
        Listing memory targetListing = listings[listingID];
        return (
            targetListing.listerAddress,
            targetListing.nftContractAddress,
            targetListing.nftID,
            targetListing.quantity,
            targetListing.btPricePerFraction
        );
    }

    function getListing(uint256 listingID) external view returns (address, uint256, uint256, uint256) {
        uint256 referanceRate = getCurrentBTQTRate();
        Listing memory targetListing = listings[listingID];
        return (
            targetListing.nftContractAddress,
            targetListing.nftID,
            targetListing.quantity,
            _convertBTPriceToQT(targetListing.btPricePerFraction, referanceRate)
        );
    }

    function getListingQuantityLeft(uint256 listingID) external view returns (uint256) {
        return listings[listingID].quantity;
    }

    function checkListingQTPrice(uint256 listingID) external view returns (uint256) {
        return _convertBTPriceToQT(listings[listingID].btPricePerFraction, getReferenceBTQTRate());
    }

    // ======================================
    // =           Price Related            =
    // ======================================
    function convertBTToQT(uint256 btAmount, bool basedOnCurrentRate) public view returns (uint256) {
        if (basedOnCurrentRate) {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = uint32(uniswapObservationTime);
            secondsAgos[1] = 0;

            int56 uniswapObservationTimeTypeChanged = int56(int256(uniswapObservationTime));

            (int56[] memory tickCumulatives,) = DEX_POOL.observe(secondsAgos);
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int24 tick = int24(tickCumulativesDelta / uniswapObservationTimeTypeChanged);
            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % uniswapObservationTimeTypeChanged != 0)) tick--;
            return uint256(getQuoteAtTick(tick, uint128(btAmount), BASE_TOKEN_ADDRESS, QUOTE_TOKEN_ADDRESS));
        } else {
            return btAmount * getReferenceBTQTRate();
        }
    }

    function getCurrentBTQTRate() public view returns (uint256) {
        return convertBTToQT(1, true);
    }

    function checkRatePeriod() public view returns (RatePeriod) {
        if (block.timestamp < lastBTQTRateLockTimestamp + rateLockDuration) {
            return RatePeriod.LOCK;
        } else if (block.timestamp < lastBTQTRateLockTimestamp + 2 * rateLockDuration) {
            if (lockedBTQTRate == lastCheckedBTQTRate) return RatePeriod.FLOATING;
            return RatePeriod.NEW_LOCK;
        } else {
            return RatePeriod.FLOATING;
        }
    }

    // To the rateDifference
    function _getAdjustedCurrentBTQTRate() private view returns (uint256) {
        uint256 currentRate = getCurrentBTQTRate();
        uint256 tolerance =
            (FIXED_POINT_PRECISION * lastCheckedBTQTRate * rateSlippageTolerance / 100) / FIXED_POINT_PRECISION;
        uint256 upperLimit = lastCheckedBTQTRate + tolerance;
        uint256 lowerLimit = lastCheckedBTQTRate - tolerance;

        if (currentRate < lowerLimit || currentRate > upperLimit) return _roundNumber(currentRate, 2);
        else return lastCheckedBTQTRate;
    }

    function _getReferenceRate(RatePeriod period) internal view returns (uint256) {
        if (!isRatePeriodSystemEnabled || period == RatePeriod.LOCK) {
            return lockedBTQTRate;
        } else if (period == RatePeriod.NEW_LOCK) {
            return lastCheckedBTQTRate;
        } else {
            return _getAdjustedCurrentBTQTRate();
        }
    }

    function getReferenceBTQTRate() public view returns (uint256) {
        return _getReferenceRate(checkRatePeriod());
    }

    function _roundPrice(uint256 price) private view returns (uint256) {
        uint256 digitCount = _findDigitCount(price);
        if (digitCount <= QT_DECIMAL_COUNT + 1) return 0;
        else return _roundNumber(price, digitCount - QT_DECIMAL_COUNT);
    }

    function _convertBTPriceToQT(uint256 btPrice, uint256 referanceRate) internal view returns (uint256) {
        return _roundPrice(btPrice * referanceRate);
    }

    function convertBTPriceToQT(uint256 btPrice) external view returns (uint256) {
        return _roundPrice(btPrice * getReferenceBTQTRate());
    }
}
