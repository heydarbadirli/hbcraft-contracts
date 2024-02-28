// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./ProgramManager.sol";

abstract contract AccessControl is ProgramManager {
    // ======================================
    // =          State Variables           =
    // ======================================
    /**
     *     - Certain functions can be called only if you have the matching AccessTier requirement
     *     - Tier 2 - Contract Owner, Tier 1 - Contract Admins, Tier 0 - Users
     *     - Check ComplianceCheck.sol for more info
     */
    enum AccessTier {
        ADMIN,
        OWNER
    }

    address public contractOwner;
    mapping(address => bool) public contractAdmins;

    // ======================================
    // =              Errors                =
    // ======================================
    error UnauthorizedAccess(AccessTier requiredAccessTier);

    // ======================================
    // =             Functions              =
    // ======================================
    // Functions to check authorization and revert if not authorized
    function _checkAccess(AccessTier tierToCheck) private view {
        if (tierToCheck == AccessTier.OWNER && msg.sender != contractOwner) {
            revert UnauthorizedAccess(tierToCheck);
        } else if (tierToCheck == AccessTier.ADMIN && !contractAdmins[msg.sender] && msg.sender != contractOwner) {
            revert UnauthorizedAccess(tierToCheck);
        }
    }

    // ======================================
    // =             Modifiers              =
    // ======================================
    /// @dev The functions only accesible by the address deployed the contract
    modifier onlyContractOwner() {
        _checkAccess(AccessTier.OWNER);
        _;
    }

    /**
     * @dev
     *     - The functions only accesible by the contractOwner and the addresses that have admin status
     *     - The admin status can only be assigned by the address deployed the contract
     *
     */
    modifier onlyAdmins() {
        _checkAccess(AccessTier.ADMIN);
        _;
    }
}
