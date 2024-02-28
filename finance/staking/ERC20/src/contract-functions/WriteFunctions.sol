// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "../ComplianceCheck.sol";

abstract contract WriteFunctions is ComplianceCheck {
    function _updateStakerBalance(ActionType action, uint256 poolID, address userAddress, uint256 tokenAmount)
        private
    {
        StakingPool storage targetPool = stakingPoolList[poolID];
        if (action == ActionType.STAKING) {
            targetPool.stakerList[userAddress] += tokenAmount;
            targetPool.totalList[DataType.STAKED] += tokenAmount;
        } else if (action == ActionType.WITHDRAWAL) {
            targetPool.stakerList[userAddress] -= tokenAmount;
            targetPool.totalList[DataType.STAKED] -= tokenAmount;

            targetPool.withdrawerList[userAddress] += tokenAmount;
            targetPool.totalList[DataType.WITHDREW] += tokenAmount;
        } else if (action == ActionType.INTEREST_CLAIM) {
            targetPool.interestClaimerList[userAddress] += tokenAmount;
            targetPool.totalList[DataType.INTEREST_CLAIMED] += tokenAmount;
        }
    }

    function _updatePoolData(
        ActionType action,
        uint256 poolID,
        address userAddress,
        uint256 depositNumber,
        uint256 tokenAmount
    ) internal {
        StakingPool storage targetPool = stakingPoolList[poolID];
        TokenDeposit[] storage targetDepositList = targetPool.stakerDepositList[userAddress];

        if (action == ActionType.STAKING) {
            if (targetDepositList.length == 0) {
                targetPool.stakerAddressList.push(userAddress);
            }
            targetDepositList.push(TokenDeposit(block.timestamp, 0, tokenAmount, targetPool.APY, 0));
            _updateStakerBalance(action, poolID, userAddress, tokenAmount);
        } else if (action == ActionType.WITHDRAWAL) {
            TokenDeposit storage targetDeposit = targetDepositList[depositNumber];
            targetDeposit.withdrawalDate = block.timestamp;
            _updateStakerBalance(action, poolID, userAddress, tokenAmount);
        } else if (action == ActionType.INTEREST_CLAIM) {
            TokenDeposit storage targetDeposit = targetDepositList[depositNumber];
            targetDeposit.claimedInterest += tokenAmount;
            _updateStakerBalance(action, poolID, userAddress, tokenAmount);
        }
    }
}
