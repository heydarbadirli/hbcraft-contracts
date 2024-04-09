// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.22;

import "../ComplianceCheck.sol";

abstract contract AuxiliaryFunctions is ComplianceCheck {
    function getAllListingProperties()
        external
        view
        returns (address[] memory, address[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        Listing[] memory _listings = listings;
        uint256 listingCount = _listings.length;

        address[] memory listerAddresses = new address[](listingCount);
        address[] memory nftContractAddresses = new address[](listingCount);
        uint256[] memory nftIDs = new uint256[](listingCount);
        uint256[] memory quantities = new uint256[](listingCount);
        uint256[] memory prices = new uint256[](listingCount);

        for (uint256 listingID = 0; listingID < listingCount; listingID++) {
            Listing memory targetListing = _listings[listingID];

            listerAddresses[listingID] = targetListing.listerAddress;
            nftContractAddresses[listingID] = targetListing.nftContractAddress;
            nftIDs[listingID] = targetListing.nftID;
            quantities[listingID] = targetListing.quantity;
            prices[listingID] = targetListing.btPricePerFraction;
        }

        return (listerAddresses, nftContractAddresses, nftIDs, quantities, prices);
    }

    function getAllValidListings()
        external
        view
        returns (uint256[] memory, address[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256[] memory activeListingIDs = getValidListingIDs();
        uint256 activeListingCount = activeListingIDs.length;

        uint256[] memory listingIDs = new uint256[](activeListingCount);
        address[] memory nftContractAddresses = new address[](activeListingCount);
        uint256[] memory nftIDs = new uint256[](activeListingCount);
        uint256[] memory quantities = new uint256[](activeListingCount);
        uint256[] memory prices = new uint256[](activeListingCount);

        for (uint256 count = 0; count < activeListingCount; count++) {
            uint256 listingID = activeListingIDs[count];
            Listing memory targetListing = listings[listingID];

            listingIDs[count] = listingID;
            nftContractAddresses[count] = targetListing.nftContractAddress;
            nftIDs[count] = targetListing.nftID;
            quantities[count] = targetListing.quantity;
            prices[count] = convertBTPriceToQT(targetListing.btPricePerFraction);
        }

        return (listingIDs, nftContractAddresses, nftIDs, quantities, prices);
    }
}
