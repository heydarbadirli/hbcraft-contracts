// SPDX-License-Identifier: CC-BY-4.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

contract WithdrawFunctions is ReadFunctions, WriteFunctions {
    // ======================================
    // =     Interest Claim Functions       =
    // ======================================
    function _calculateDaysPassed(uint256 startDate) private view
    returns(uint256) {
        uint256 timePassed;

        // Calculate the time passed in seconds
        if (programEndDate == 0 || block.timestamp <= programEndDate) {
            timePassed = block.timestamp - startDate;
        } else {
            timePassed = programEndDate - startDate;
        }

        // Convert the time elapsed to days
        uint256 daysPassed = timePassed / 60 / 60 / 24;
        return daysPassed;
    }

    function _calculateInterest(uint256 poolID, address userAddress, uint256 depositNumber) private view
    returns(uint256) {
        uint256 daysPassed;
        uint256 depositAPY;
        uint256 depositAmount;
        uint256 interestAlreadyClaimed;

        uint256 claimableInterest;

        // A local variable to refer to the appropriate TokenDeposit
        // Check if assigning by reference works
        TokenDeposit storage deposit = stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];

        daysPassed = _calculateDaysPassed(deposit.stakingDate);
        depositAPY = deposit.APY;
        depositAmount = deposit.amount;
        interestAlreadyClaimed = deposit.claimedInterest;

        claimableInterest = ((depositAmount * ((depositAPY / 365) * daysPassed) / 100) - interestAlreadyClaimed) / 1 ether;
        return claimableInterest;
    }

    function checkClaimableInterest(uint256 poolID, address userAddress, uint256 depositNumber) external view
    returns (uint256) {
        return _calculateInterest(poolID, userAddress, depositNumber) / 1 ether;
    }

    function _processInterestClaim(uint256 poolID, address userAddress, uint256 depositNumber, bool isBatchClaim) private {
        uint256 interestToClaim = _calculateInterest(poolID, userAddress, depositNumber);
        require(interestPool >= interestToClaim, "Not enough funds in the Interest Pool");

        if (interestToClaim == 0){
            if (isBatchClaim == false){
                revert("Nothing to Claim");
            }
        } else {
            _updatePoolData(ActionType.INTEREST_CLAIM, poolID, msg.sender, depositNumber, interestToClaim);
            interestPool -= interestToClaim;

            _sendToken(msg.sender, interestToClaim);
            emit ClaimInterest(msg.sender, poolID, depositNumber, interestToClaim);
        }
    }

    // NOTICE: isBatchClaim = true because the function is called by withdraw function and we don't want to raise an exception when nothing to claim
    function _claimInterest(uint256 poolID, address userAddress, uint256 depositNumber) private {
        _processInterestClaim(poolID, userAddress, depositNumber, true);
    }

    function claimInterest(uint256 poolID, uint256 depositNumber) external
    nonReentrant {
        _processInterestClaim(poolID, msg.sender, depositNumber, false);
    }

    function claimAllInterest(uint256 poolID) external
    nonReentrant {
        for (uint256 depositNumber = 0; depositNumber < stakingPoolList[poolID].stakerDepositList[msg.sender].length; depositNumber++){
            _processInterestClaim(poolID, msg.sender, depositNumber, true);
        }
    }

    // ======================================
    // =    Withdraw Related Functions      =
    // ======================================
    function _withdrawDeposit(uint256 poolID, uint256 depositNumber) private
    ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
    sufficientBalance(poolID)
    enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber].amount) {
        _claimInterest(poolID, msg.sender, depositNumber);
        TokenDeposit storage targetDeposit = stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber];

        // Update the staking pool balances
        uint256 amountToWithdraw = targetDeposit.amount;
        _updatePoolData(ActionType.WITHDRAWAL, poolID, msg.sender, depositNumber, amountToWithdraw);

        _sendToken(msg.sender, amountToWithdraw);
        emit Withdraw(msg.sender, poolID, stakingPoolList[poolID].poolType, depositNumber, amountToWithdraw);
    }

    function withdrawDeposit(uint256 poolID, uint256 depositNumber) external
    nonReentrant {
        _withdrawDeposit(poolID, depositNumber);
    }

    function withdrawAll(uint256 poolID) external
    nonReentrant {
        StakingPool storage targetPool = stakingPoolList[poolID];
        TokenDeposit[] storage targetDepositList = targetPool.stakerDepositList[msg.sender];

        for(uint128 depositNumber = 0; depositNumber < targetDepositList.length; depositNumber++){
            _withdrawDeposit(poolID, depositNumber);
        }
    }
}