// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.22;

import "../AccessControl.sol";
import "./MathFunctions.sol";

abstract contract ReadFunctions is AccessControl, MathFunctions {
    // ======================================
    // =         Listing Related            =
    // ======================================
    function checkTotalListingCount() external view returns (uint256) {
        return listings.length;
    }

    function checkIfListingCompleted(uint256 listingID) external view returns (bool) {
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
        Listing memory targetListing = listings[listingID];
        return (
            targetListing.nftContractAddress,
            targetListing.nftID,
            targetListing.quantity,
            convertBTPriceToQT(targetListing.btPricePerFraction)
        );
    }

    function getListingQuantityLeft(uint256 listingID) external view returns (uint256) {
        return listings[listingID].quantity;
    }

    function checkListingQTPrice(uint256 listingID) external view returns (uint256) {
        return convertBTPriceToQT(listings[listingID].btPricePerFraction);
    }

    // ======================================
    // =           Price Related            =
    // ======================================
    function _adjustBTAmount(uint256 btAmount) private view returns (uint256) {
        if (btDecimalDifference == DecimalCount.LESS) return btAmount * DECIMAL_POINT_ADJUSTMENT;
        else if (btDecimalDifference == DecimalCount.MORE) return btAmount / DECIMAL_POINT_ADJUSTMENT;
        else return btAmount;
    }

    function getCurrentBTQTRate() public view returns (uint256) {
        return FIXED_POINT_PRECISION * QUOTE_TOKEN.balanceOf(DEX_POOL_ADDRESS)
            / _adjustBTAmount(BASE_TOKEN.balanceOf(DEX_POOL_ADDRESS));
    }

    function convertToQT(uint256 btAmount, bool basedOnCurrentRate) public view returns (uint256) {
        /// ??? to be considered for optimization
        if (basedOnCurrentRate) {
            return _adjustBTAmount(btAmount) * QUOTE_TOKEN.balanceOf(DEX_POOL_ADDRESS)
                / _adjustBTAmount(BASE_TOKEN.balanceOf(DEX_POOL_ADDRESS));
        } else {
            return _adjustBTAmount(btAmount) * getReferenceBTQTRate() / FIXED_POINT_PRECISION;
        }
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
        uint256 tolerance = (FIXED_POINT_PRECISION * lastCheckedBTQTRate * rateSlippageTolerance / 100) / FIXED_POINT_PRECISION;
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

        uint256 qtDecimals = QUOTE_TOKEN.decimals();
        if (digitCount <= qtDecimals + 1) return 0;
        else return _roundNumber(price, digitCount - qtDecimals);
    }

    function convertBTPriceToQT(uint256 btPrice) public view returns (uint256) {
        return _roundPrice(convertToQT(btPrice, false));
    }
}
