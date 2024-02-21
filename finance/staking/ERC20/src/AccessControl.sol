// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity 0.8.20;

import "./ProgramManager.sol";


contract AccessControl is ProgramManager {
    // ======================================
    // =          State Variables           =
    // ======================================
    // NOTICE: Access Tiers
    // DEV: Certain functions can be called only if you have the matching AccessTier requirement
    // DEV: Tier 2 - Contract Owner, Tier 1 - Contract Admins, Tier 0 - Users
    // DEV: Check ComplianceCheck.sol for more info
    enum AccessTier { USER, ADMIN, OWNER }
    
    address public contractOwner;
    mapping (address => bool) public contractAdmins;


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
        } else if (tierToCheck == AccessTier.USER && (contractAdmins[msg.sender] || msg.sender == contractOwner)) {
            revert UnauthorizedAccess(tierToCheck);
        }
    }
    

    // ======================================
    // =             Modifiers              =
    // ======================================
    // DEV: The functions only accesible by the address deployed the contract
    modifier onlyContractOwner () {
        _checkAccess(AccessTier.OWNER);
        _;
    }

    // DEV: The functions only accesible by the contractOwner and the addresses that have admin status
    // DEV: The admin status can only be assigned by the address deployed the contract
    modifier onlyAdmins () {
        _checkAccess(AccessTier.ADMIN);
        _;
    }

    // DEV: Modifies stakeToken function to make it accesible only by the users
    // DEV: For preventing collectFunds ==> stakeToken ==> collectFunds ==> ... loophole
    modifier onlyUser () {
        _checkAccess(AccessTier.USER);
        _;
    }
}