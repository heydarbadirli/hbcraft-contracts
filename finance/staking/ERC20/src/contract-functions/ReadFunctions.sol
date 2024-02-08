// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "../ComplianceCheck.sol";


contract ReadFunctions is ComplianceCheck {
    // ======================================
    // =  Functoins to check program data   =
    // ======================================
    function checkConfirmationCode() external view
    returns (uint256) {
        return confirmationCode;
    }

    function checkPoolCount() external view
    returns (uint256) {
        return _checkProgramStatus(true);
    }

    function checkDefaultStakingTarget() external view
    returns (uint256) {
        return defaultStakingTarget / tokenDecimals;
    }

    function checkDefaultMinimumDeposit() external view
    returns (uint256) {
        return defaultMinimumDeposit / tokenDecimals;
    }

    function checkInterestPool() external view
    returns (uint256) {
        return interestPool / tokenDecimals;
    }

    function checkInterestProvidedByAddress(address userAddress) external view
    returns (uint256) {
        return interestProviderList[userAddress] / tokenDecimals;
    }

    function checkInterestCollectedByAddress(address userAddress) external view
    returns (uint256) {
        return interestCollectorList[userAddress] / tokenDecimals;
    }


    // ======================================
    // =Functions to check stakingPool data =
    // ======================================
    function checkPoolType(uint256 poolID) external view
    returns (uint256) {
        return (stakingPoolList[poolID].poolType == PoolType.LOCKED) ? 0 : 1;
    }

    function checkStakingTarget(uint256 poolID) external view
    returns (uint256) {
        return stakingPoolList[poolID].stakingTarget / tokenDecimals;
    }

    function checkMinimumDeposit(uint256 poolID) external view
    returns (uint256) {
        return stakingPoolList[poolID].minimumDeposit / tokenDecimals;
    }

    function checkAPY(uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].APY / tokenDecimals;
    }

    // DEV: Returns timestamp
    function checkEndDate(uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].endDate;
    }

    // DEV: Availability status requests
    function checkIfStakingOpen(uint256 poolID) external view 
    returns (bool){
        return stakingPoolList[poolID].isStakingOpen;
    }

    function checkIfWithdrawalOpen(uint256 poolID) external view
    returns (bool){
        return stakingPoolList[poolID].isWithdrawalOpen;
    }

    function checkIfInterestClaimOpen(uint256 poolID) external view
    returns (bool){
        return stakingPoolList[poolID].isInterestClaimOpen;
    }

    function checkIfPoolEnded(uint256 poolID) external view
    returns (bool){
        return _checkIfPoolEnded(poolID, true);
    }

    // DEV: Total data requests
    function checkTotalStaked(uint256 poolID) public view
    returns (uint256){
        return stakingPoolList[poolID].totalList[DataType.STAKED] / tokenDecimals;
    }

    function checkTotalWithdrawn(uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].totalList[DataType.WITHDREW] / tokenDecimals;
    }

    function checkTotalInterestClaimed(uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].totalList[DataType.INTEREST_CLAIMED] / tokenDecimals;
    }

    function checkTotalFundCollected(uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].totalList[DataType.FUNDS_COLLECTED] / tokenDecimals;
    }


    // ======================================
    // =    Functoins to check user data    =
    // ======================================
    function checkStakedAmountByAddress(address userAddress, uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].stakerList[userAddress] / tokenDecimals;
    }

    function checkWithdrawnAmountByAddress(address userAddress, uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].withdrawerList[userAddress] / tokenDecimals;
    }

    function checkInterestClaimedByAddress(address userAddress, uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].interestClaimerList[userAddress] / tokenDecimals;
    }

    function checkCollectedFundsByAddress(address userAddress, uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].fundCollectorList[userAddress] / tokenDecimals;
    }

    function checkDepositCountOfAddress(address userAddress, uint256 poolID) external view
    returns (uint256){
        return stakingPoolList[poolID].stakerDepositList[userAddress].length;
    }
}