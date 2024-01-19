// SPDX-License-Identifier: CC-BY-4.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;

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
    // =             Modifiers              =
    // ======================================
    // DEV: The functions only accesible by the address deployed the contract
    modifier onlyContractOwner () {
            if (msg.sender != contractOwner){
                revert UnauthorizedAccess(AccessTier.OWNER);
            }
            _;
        }

    // DEV: The functions only accesible by the contractOwner and the addresses that have admin status
    // DEV: The admin status can only be assigned by the address deployed the contract
    modifier onlyAdmins () {
            if (contractAdmins[msg.sender] != true && msg.sender != contractOwner){
                revert UnauthorizedAccess(AccessTier.ADMIN);
            }
            _;
        }
}