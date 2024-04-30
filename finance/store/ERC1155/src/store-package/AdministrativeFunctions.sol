// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./AuxiliaryFunctions.sol";

abstract contract AdministrativeFunctions is AuxiliaryFunctions {
    // ======================================
    // =          Access Related            =
    // ======================================
    function transferOwnership(address newOwnerAddress) external onlyContractOwner {
        if (contractOwner == newOwnerAddress) revert ValueReassignment();
        require(newOwnerAddress != address(0), "New contract owner can not be zero");
        contractOwner = newOwnerAddress;
        emit TransferOwnership(newOwnerAddress);
    }

    function changeTreasuryAddress(address newTreasuryAddress) external onlyTreasury {
        if (treasury == newTreasuryAddress) revert ValueReassignment();
        require(newTreasuryAddress != address(0), "New treasury can not be zero");
        treasury = newTreasuryAddress;
        emit ChangeTreasuryAddress(newTreasuryAddress);
    }

    function addLister(address listerAddress) external onlyContractOwner {
        if (isLister[listerAddress]) revert ValueReassignment();
        require(listerAddress != address(0), "Lister can not be zero");
        isLister[listerAddress] = true;
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
        nftListingID[nftContractAddress][nftID] = listings.length;
        emit CreateListing(listings.length, nftContractAddress, nftID, quantity, btPrice);
    }

    function cancelListing(uint256 listingID) external ifListingExists(listingID) ifListingOwner(listingID) {
        Listing memory targetListing = listings[listingID];
        if (!targetListing.isActive) revert ValueReassignment();
        listings[listingID].isActive = false;
        nftListingID[targetListing.nftContractAddress][targetListing.nftID] = 0;
        uint256[] memory activeListingIDs = getActiveListingIDs();
        if (activeListingIDs.length != 0) activeListingStartIndex = activeListingIDs[0];
        emit CancelListing(listingID);
    }

    // ======================================
    // =          Pricing Related           =
    // ======================================
    function setMinimumPriceInQT(uint256 qtAmount) external onlyContractOwner {
        if (qtAmount < FIXED_POINT_PRECISION) revert InvalidArgumentValue("qtAmount", FIXED_POINT_PRECISION);
        minimumPriceInQT = qtAmount;
        emit SetMinimumPriceInQT(qtAmount);
    }

    function setMinimumAcceptableRate(uint256 newMinRate) external onlyContractOwner {
        minimumAcceptableRate = newMinRate;
        emit SetMinimumAcceptableRate(newMinRate);
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
