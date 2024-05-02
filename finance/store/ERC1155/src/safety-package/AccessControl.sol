// SPDX-License-Identifier: GPL-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "../store-package/StoreManager.sol";

abstract contract AccessControl is StoreManager {
    address public contractOwner;
    address public treasury;
    mapping(address => bool) public isLister;

    enum AccessTier {
        LISTER,
        TREASURY,
        OWNER
    }

    // ======================================
    // =              Errors                =
    // ======================================
    error UnauthorizedAccess(AccessTier requiredAccessTier);
    error NotListingOwner(address listingOwner);

    // ======================================
    // =             Functions              =
    // ======================================
    /// @dev Functions to check authorization and revert if not authorized
    function _checkAccess(AccessTier tierToCheck) private view {
        if (tierToCheck == AccessTier.OWNER && msg.sender != contractOwner) {
            revert UnauthorizedAccess(tierToCheck);
        } else if (tierToCheck == AccessTier.TREASURY && msg.sender != treasury) {
            revert UnauthorizedAccess(tierToCheck);
        } else if (tierToCheck == AccessTier.LISTER && !isLister[msg.sender]) {
            revert UnauthorizedAccess(tierToCheck);
        }
    }

    function _checkListingOwnership(uint256 listingID) private view {
        address listingOwner = listings[listingID].listerAddress;
        if (msg.sender != listingOwner && msg.sender != contractOwner) revert NotListingOwner(listingOwner);
    }

    // ======================================
    // =             Modifiers              =
    // ======================================
    /// @dev The functions only accesible by the contractOwner
    modifier onlyContractOwner() {
        _checkAccess(AccessTier.OWNER);
        _;
    }

    /// @dev The functions only accesible by the treasury
    modifier onlyTreasury() {
        _checkAccess(AccessTier.TREASURY);
        _;
    }

    /// @dev The functions only accesible by the listers
    modifier onlyLister() {
        _checkAccess(AccessTier.LISTER);
        _;
    }

    /// @dev The functions only accesible by the owner of the listing or the contractOwner
    modifier ifListingOwner(uint256 listingID) {
        _checkListingOwnership(listingID);
        _;
    }
}
