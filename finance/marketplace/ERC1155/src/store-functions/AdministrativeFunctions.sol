// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.22;

import "../contract-functions/AuxiliaryFunctions.sol";

abstract contract AdministrativeFunctions is AuxiliaryFunctions {
    // ======================================
    // =          Access Related            =
    // ======================================
    function transferOwnership(address newOwnerAddress) external onlyContractOwner {
        if (contractOwner == newOwnerAddress) revert ValueReassignment();
        contractOwner = newOwnerAddress;
    }

    function addLister(address listerAddress) external onlyContractOwner {
        if (isLister[listerAddress]) revert ValueReassignment();
        else isLister[listerAddress] = true;
    }

    function removeLister(address listerAddress) external onlyContractOwner {
        if (!isLister[listerAddress]) revert ValueReassignment();
        else isLister[listerAddress] = false;
    }

    // ======================================
    // =          Listing Related           =
    // ======================================
    function createListing(address nftContractAddress, uint256 nftID, uint256 quantity, uint256 btPrice)
        external
        onlyLister
        ifStoreContractApprovedByLister(msg.sender, nftContractAddress)
        ifListingMeetsListingReqs(nftContractAddress, nftID, quantity, btPrice)
    {
        listings.push(Listing(msg.sender, nftContractAddress, nftID, quantity, btPrice, true));
    }

    function cancelListing(uint256 listingID) external ifListingExists(listingID) ifListingOwner(listingID) {
        if (!listings[listingID].isActive) revert ValueReassignment();
        listings[listingID].isActive = false;
        uint256[] memory activeListingIDs = getActiveListingIDs();
        if (activeListingIDs.length != 0) activeListingStartIndex = activeListingIDs[0];
    }

    // ======================================
    // =          Pricing Related           =
    // ======================================
    function setListingBTPrice(uint256 listingID, uint256 btAmount) external ifListingOwner(listingID) {
        listings[listingID].btPricePerFraction = btAmount;
    }

    function setMinimumPriceInQT(uint256 qtAmount) external onlyContractOwner {
        minimumPriceInQT = qtAmount;
    }

    function setRateSlippageTolerance(uint256 percent) external onlyContractOwner {
        rateSlippageTolerance = percent;
    }

    function resetLockPeriod() external onlyContractOwner {
        _updateStateVariables(RatePeriod.FLOATING);
    }

    function setAutoPricingStatus(bool isEnabled) external onlyContractOwner {
        if (isAutoPricingEnabled == isEnabled) revert ValueReassignment();
        isAutoPricingEnabled = isEnabled;
    }

    function setBTQTRate() external onlyContractOwner {
        lockedBTQTRate = getCurrentBTQTRate();
    }
}
