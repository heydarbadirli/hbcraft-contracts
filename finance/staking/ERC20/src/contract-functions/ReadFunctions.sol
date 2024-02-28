// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "../ComplianceCheck.sol";

abstract contract ReadFunctions is ComplianceCheck {
    // ======================================
    // =  Functoins to check program data   =
    // ======================================
    function checkConfirmationCode() external view returns (uint256) {
        return CONFIRMATION_CODE;
    }

    function checkPoolCount() external view returns (uint256) {
        return _checkProgramStatus(true);
    }

    function checkDefaultStakingTarget() external view returns (uint256) {
        return defaultStakingTarget;
    }

    function checkDefaultMinimumDeposit() external view returns (uint256) {
        return defaultMinimumDeposit;
    }

    function checkInterestPool() external view returns (uint256) {
        return interestPool;
    }

    function checkInterestProvidedBy(address userAddress) external view returns (uint256) {
        return interestProviderList[userAddress];
    }

    // ======================================
    // =Functions to check stakingPool data =
    // ======================================
    function checkPoolType(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return (stakingPoolList[poolID].poolType == PoolType.LOCKED) ? 0 : 1;
    }

    function checkStakingTarget(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].stakingTarget;
    }

    function checkMinimumDeposit(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].minimumDeposit;
    }

    function checkAPY(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].APY / FIXED_POINT_PRECISION;
    }

    /// @dev Returns timestamp
    function checkEndDate(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].endDate;
    }

    /// @dev Availability status requests
    function checkIfStakingOpen(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return stakingPoolList[poolID].isStakingOpen;
    }

    function checkIfWithdrawalOpen(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return stakingPoolList[poolID].isWithdrawalOpen;
    }

    function checkIfInterestClaimOpen(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return stakingPoolList[poolID].isInterestClaimOpen;
    }

    function checkIfPoolEnded(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return _checkIfPoolEnded(poolID, true);
    }

    /// @dev Total data requests
    function checkTotalStaked(uint256 poolID) public view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.STAKED];
    }

    function checkTotalWithdrawn(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.WITHDREW];
    }

    function checkTotalInterestClaimed(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.INTEREST_CLAIMED];
    }

    function checkTotalFundCollected(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.FUNDS_COLLECTED];
    }

    function checkTotalFundRestored(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.FUNDS_RESTORED];
    }

    // ======================================
    // =    Functoins to check user data    =
    // ======================================
    function checkStakedAmountBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].stakerList[userAddress];
    }

    function checkDepositStakedAmount(address userAddress, uint256 poolID, uint256 depositNumber)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber].amount;
    }

    function checkWithdrawnAmountBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].withdrawerList[userAddress];
    }

    function checkInterestClaimedBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].interestClaimerList[userAddress];
    }

    function checkRestoredFundsBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].fundRestorerList[userAddress];
    }

    function checkDepositCountOfAddress(address userAddress, uint256 poolID)
        public
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].stakerDepositList[userAddress].length;
    }
}
