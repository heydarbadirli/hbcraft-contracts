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
        emit TransferOwnership(newOwnerAddress);
    }

    function changeTreasuryAddress(address newTreasuryAddress) external onlyTreasury {
        if (treasury == newTreasuryAddress) revert ValueReassignment();
        treasury = newTreasuryAddress;
        emit ChangeTreasuryAddress(newTreasuryAddress);
    }

    function addLister(address listerAddress) external onlyContractOwner {
        if (isLister[listerAddress]) revert ValueReassignment();
        else isLister[listerAddress] = true;
        emit AddLister(listerAddress);
    }

    function removeLister(address listerAddress) external onlyContractOwner {
        if (!isLister[listerAddress]) revert ValueReassignment();
        else isLister[listerAddress] = false;
        emit RemoveLister(listerAddress);
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
        emit CreateListing(nftContractAddress, nftID, quantity, btPrice);
    }

    function cancelListing(uint256 listingID) external ifListingExists(listingID) ifListingOwner(listingID) {
        if (!listings[listingID].isActive) revert ValueReassignment();
        listings[listingID].isActive = false;
        uint256[] memory activeListingIDs = getActiveListingIDs();
        if (activeListingIDs.length != 0) activeListingStartIndex = activeListingIDs[0];
        emit CancelListing(listingID);
    }

    // ======================================
    // =          Pricing Related           =
    // ======================================
    function setListingBTPrice(uint256 listingID, uint256 btAmount) external ifListingOwner(listingID) {
        listings[listingID].btPricePerFraction = btAmount;
        emit SetListingBTPrice(listingID, btAmount);
    }

    function setMinimumPriceInQT(uint256 qtAmount) external onlyContractOwner {
        minimumPriceInQT = qtAmount;
        emit SetMinimumPriceInQT(qtAmount);
    }

    function setRateSlippageTolerance(uint256 percent) external onlyContractOwner {
        rateSlippageTolerance = percent;
        emit SetRateSlippageTolerance(percent);
    }

    function setRateLockDuration(uint256 durationInSeconds) external onlyContractOwner {
        rateLockDuration = durationInSeconds;
        emit SetRateLockDuration(durationInSeconds);
    }

    function resetLockPeriod() external onlyContractOwner {
        _updateStateVariables(RatePeriod.FLOATING);
        emit ResetLockPeriod();
    }

    function setRatePeriodSystemStatus(bool isEnabled) external onlyContractOwner {
        if (isRatePeriodSystemEnabled == isEnabled) revert ValueReassignment();
        isRatePeriodSystemEnabled = isEnabled;
        emit SetRatePeriodSystemStatus(isEnabled);
    }

    function setBTQTRate() external onlyContractOwner {
        uint256 newRate = getCurrentBTQTRate();
        lockedBTQTRate = newRate;
        emit SetBTQTRate(newRate);
    }
}
