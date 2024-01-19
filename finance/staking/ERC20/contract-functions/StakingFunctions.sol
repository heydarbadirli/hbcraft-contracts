// SPDX-License-Identifier: CC-BY-4.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "./ReadFunctions.sol";
import "./WriteFunctions.sol";
import "../libraries/ArrayLibrary.sol";


contract StakingFunctions is ReadFunctions, WriteFunctions {
    // DEV: For using all functions from ArrayLib as methods on uint256[] arrays
    // DEV: array.sum() to calculate the sum of elements in the array
    using ArrayLibrary for uint256[];

    function stakeToken(uint256 poolID, uint256 etherAmount) external
    nonReentrant
    ifAvailable(poolID, PoolDataType.IS_STAKING_OPEN)
    enoughTokenSent(etherAmount * 1 ether, stakingPoolList[poolID].minimumDeposit)
    ifTargetReached(etherAmount, checkTotalStaked().sum()) {
        uint256 etherToWeiAmount = etherAmount * 1 ether;
        _receiveToken(etherToWeiAmount);

        // Update the staking pool balances
        _updatePoolData(ActionType.STAKING, poolID, msg.sender, 0, etherToWeiAmount);

        StakingPool storage targetPool = stakingPoolList[poolID];
        emit Stake(msg.sender, poolID, targetPool.poolType, targetPool.stakerDepositList[msg.sender].length - 1,  etherAmount);
    }
}
