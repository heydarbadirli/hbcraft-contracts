// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

abstract contract WithdrawFunctions is ReadFunctions, WriteFunctions {
    // ======================================
    // =     Interest Claim Functions       =
    // ======================================
    function _calculateDaysPassed(uint256 poolID, uint256 startDate, uint256 withdrawalDate)
        private
        view
        returns (uint256)
    {
        uint256 timePassed;
        uint256 poolEndDate = stakingPoolList[poolID].endDate;

        if (withdrawalDate != 0) {
            if (poolEndDate == 0 || withdrawalDate <= poolEndDate) {
                timePassed = withdrawalDate - startDate;
            } else if (withdrawalDate > poolEndDate) {
                timePassed = poolEndDate - startDate;
            }
        } else if (poolEndDate != 0) {
            timePassed = poolEndDate - startDate;
        } else {
            timePassed = block.timestamp - startDate;
        }

        // Convert the time elapsed to days
        uint256 daysPassed = timePassed / (1 days);
        return daysPassed;
    }

    function _calculateInterest(uint256 poolID, address userAddress, uint256 depositNumber)
        private
        view
        returns (uint256)
    {
        uint256 daysPassed;
        uint256 depositAPY;
        uint256 depositAmount;
        uint256 interestAlreadyClaimed;

        uint256 claimableInterest;

        // A local variable to refer to the appropriate TokenDeposit
        TokenDeposit storage deposit = stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];

        daysPassed = _calculateDaysPassed(poolID, deposit.stakingDate, deposit.withdrawalDate);
        depositAPY = deposit.APY;
        depositAmount = deposit.amount;
        interestAlreadyClaimed = deposit.claimedInterest;

        claimableInterest = (((depositAmount * ((depositAPY / 365) * daysPassed) / 100)) / FIXED_POINT_PRECISION)
            - interestAlreadyClaimed;
        return claimableInterest;
    }

    function _checkClaimableInterestBy(address userAddress, uint256 poolID, uint256 depositNumber)
        private
        view
        returns (uint256)
    {
        return _calculateInterest(poolID, userAddress, depositNumber);
    }

    function checkClaimableInterestBy(address userAddress, uint256 poolID, uint256 depositNumber)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _calculateInterest(poolID, userAddress, depositNumber);
    }

    function checkTotalClaimableInterestBy(address userAddress, uint256 poolID) public view returns (uint256) {
        uint256 userDepositCount = checkDepositCountOfAddress(userAddress, poolID);
        uint256 totalClaimableInterest = 0;

        for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
            totalClaimableInterest += _checkClaimableInterestBy(userAddress, poolID, depositNumber);
        }

        return totalClaimableInterest;
    }

    function checkTotalClaimableInterest(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        uint256 totalClaimableInterest = 0;

        for (uint256 stakerNo = 0; stakerNo < stakingPoolList[poolID].stakerAddressList.length; stakerNo++) {
            totalClaimableInterest +=
                checkTotalClaimableInterestBy(stakingPoolList[poolID].stakerAddressList[stakerNo], poolID);
        }

        return totalClaimableInterest;
    }

    function checkGeneratedInterestLastDayFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        uint256 userDepositCount = checkDepositCountOfAddress(userAddress, poolID);
        uint256 totalLastDayGenerated = 0;

        StakingPool storage targetStakingPool = stakingPoolList[poolID];
        for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
            TokenDeposit storage targetDeposit = targetStakingPool.stakerDepositList[userAddress][depositNumber];
            if (targetDeposit.withdrawalDate == 0 && (((block.timestamp - targetDeposit.stakingDate) / (1 days)) >= 1))
            {
                totalLastDayGenerated +=
                    (targetDeposit.amount * (targetDeposit.APY / 365) / 100) / FIXED_POINT_PRECISION;
            }
        }

        return totalLastDayGenerated;
    }

    function checkGeneratedInterestDailyTotal(uint256 poolID, bool ifPrecise)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        uint256 dailyTotalInterestGenerated = 0;

        if (ifPrecise) {
            address userAddress;
            uint256 userDepositCount;

            for (uint256 stakerNo = 0; stakerNo < stakingPoolList[poolID].stakerAddressList.length; stakerNo++) {
                userAddress = stakingPoolList[poolID].stakerAddressList[stakerNo];
                userDepositCount = checkDepositCountOfAddress(userAddress, poolID);

                for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
                    TokenDeposit storage targetDeposit =
                        stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];
                    if (targetDeposit.withdrawalDate == 0) {
                        dailyTotalInterestGenerated +=
                            (targetDeposit.amount * (targetDeposit.APY / 365) / 100) / FIXED_POINT_PRECISION;
                    }
                }
            }
        } else {
            StakingPool storage targetStakingPool = stakingPoolList[poolID];
            dailyTotalInterestGenerated = (
                targetStakingPool.totalList[DataType.STAKED] * (targetStakingPool.APY / 365) / 100
            ) / FIXED_POINT_PRECISION;
        }

        return dailyTotalInterestGenerated;
    }

    function _processInterestClaim(uint256 poolID, address userAddress, uint256 depositNumber, bool isBatchClaim)
        private
    {
        uint256 interestToClaim = _calculateInterest(poolID, userAddress, depositNumber);

        if (!isBatchClaim) {
            if (interestPool < interestToClaim) {
                revert NotEnoughFundsInTheInterestPool(interestToClaim, interestPool);
            }

            if (interestToClaim == 0) {
                revert("Nothing to Claim");
            }
        }

        if (isBatchClaim && (interestPool < interestToClaim || interestToClaim == 0)) {
            // Skip claiming for this case
            return;
        }

        // Proceed with claiming process
        _updatePoolData(ActionType.INTEREST_CLAIM, poolID, msg.sender, depositNumber, interestToClaim);
        interestPool -= interestToClaim;

        emit ClaimInterest(msg.sender, poolID, depositNumber, interestToClaim);
        _sendToken(msg.sender, interestToClaim);
    }

    /// @dev isBatchClaim = true because the function is called by withdraw function and we don't want to raise an exception when nothing to claim
    function _claimInterest(uint256 poolID, address userAddress, uint256 depositNumber) private {
        bool _isInterestClaimOpen = stakingPoolList[poolID].isInterestClaimOpen;
        if (_isInterestClaimOpen) _processInterestClaim(poolID, userAddress, depositNumber, true);
    }

    function claimInterest(uint256 poolID, uint256 depositNumber)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_INTEREST_CLAIM_OPEN)
    {
        _processInterestClaim(poolID, msg.sender, depositNumber, false);
    }

    function claimAllInterest(uint256 poolID)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_INTEREST_CLAIM_OPEN)
    {
        for (
            uint256 depositNumber = 0;
            depositNumber < stakingPoolList[poolID].stakerDepositList[msg.sender].length;
            depositNumber++
        ) {
            _processInterestClaim(poolID, msg.sender, depositNumber, true);
        }
    }

    // ======================================
    // =    Withdraw Related Functions      =
    // ======================================
    function _withdrawDeposit(uint256 poolID, uint256 depositNumber, bool isBatchWithdrawal) private {
        TokenDeposit storage targetDeposit = stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber];
        uint256 depositWithdrawalDate = targetDeposit.withdrawalDate;

        if (depositWithdrawalDate != 0) {
            if (!isBatchWithdrawal) {
                revert("Deposit already withdrawn");
            }
        } else {
            _claimInterest(poolID, msg.sender, depositNumber);

            // Update the staking pool balances
            uint256 amountToWithdraw = targetDeposit.amount;
            _updatePoolData(ActionType.WITHDRAWAL, poolID, msg.sender, depositNumber, amountToWithdraw);

            emit Withdraw(msg.sender, poolID, stakingPoolList[poolID].poolType, depositNumber, amountToWithdraw);
            _sendToken(msg.sender, amountToWithdraw);
        }
    }

    function withdrawDeposit(uint256 poolID, uint256 depositNumber)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifDepositExists(poolID, depositNumber)
        ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
        enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber].amount)
    {
        _withdrawDeposit(poolID, depositNumber, false);
    }

    function withdrawAll(uint256 poolID)
        external
        nonReentrant
        ifPoolExists(poolID)
        sufficientBalance(poolID)
        ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
        enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerList[msg.sender])
    {
        StakingPool storage targetPool = stakingPoolList[poolID];
        TokenDeposit[] storage targetDepositList = targetPool.stakerDepositList[msg.sender];

        for (uint128 depositNumber = 0; depositNumber < targetDepositList.length; depositNumber++) {
            _withdrawDeposit(poolID, depositNumber, true);
        }
    }
}
