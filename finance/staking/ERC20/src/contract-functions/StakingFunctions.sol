// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "./ReadFunctions.sol";
import "./WriteFunctions.sol";
import "../libraries/ArrayLibrary.sol";


contract StakingFunctions is ReadFunctions, WriteFunctions {
    // DEV: For using all functions from ArrayLib as methods on uint256[] arrays
    // DEV: array.sum() to calculate the sum of elements in the array
    using ArrayLibrary for uint256[];

    function stakeToken(uint256 poolID, uint256 tokenAmount) external
    nonReentrant
    ifPoolExists(poolID)
    ifAvailable(poolID, PoolDataType.IS_STAKING_OPEN)
    enoughTokenSent(tokenAmount * tokenDecimals, stakingPoolList[poolID].minimumDeposit)
    ifTargetReached(tokenAmount, checkTotalStaked().sum()) {
        uint256 amountWithDecimals = tokenAmount * tokenDecimals;
        _receiveToken(amountWithDecimals);

        // Update the staking pool balances
        _updatePoolData(ActionType.STAKING, poolID, msg.sender, 0, amountWithDecimals);

        StakingPool storage targetPool = stakingPoolList[poolID];
        emit Stake(msg.sender, poolID, targetPool.poolType, targetPool.stakerDepositList[msg.sender].length - 1,  tokenAmount);
    }
}
