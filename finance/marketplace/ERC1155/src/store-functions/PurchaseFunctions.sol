// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.22;

import "../contract-functions/AuxiliaryFunctions.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract PurchaseFunctions is AuxiliaryFunctions, ReentrancyGuard {
    function _purchase(Listing memory targetListing, uint256 listingID, uint256 quantity, uint256 priceInQT) private {
        listings[listingID].quantity -= quantity;
        if (listings[listingID].quantity == 0) listings[listingID].isActive = false;
        if (isRatePeriodSystemEnabled) _updateStateForCurrentPeriod();
        _payTreasury(priceInQT * quantity);
        _transferNFTs(targetListing.listerAddress, targetListing.nftContractAddress, targetListing.nftID, quantity);
        emit Purchase(listingID, quantity, priceInQT);
    }

    function purchase(uint256 listingID, uint256 quantity)
        external
        nonReentrant
        ifPurchaseCallValid(listingID, quantity)
    {
        Listing memory targetListing = listings[listingID];

        uint256 currentPriceInQT = convertBTPriceToQT(targetListing.btPricePerFraction);
        _purchase(targetListing, listingID, quantity, currentPriceInQT);
    }

    function safePurchase(uint256 listingID, uint256 quantity, uint256 forMaxPriceInQT)
        external
        nonReentrant
        ifPurchaseCallValid(listingID, quantity)
    {
        Listing memory targetListing = listings[listingID];

        uint256 currentPriceInQT = convertBTPriceToQT(targetListing.btPricePerFraction);
        if (currentPriceInQT > forMaxPriceInQT) revert PriceInQTIncreased(listingID, forMaxPriceInQT, currentPriceInQT);

        _purchase(targetListing, listingID, quantity, currentPriceInQT);
    }
}
