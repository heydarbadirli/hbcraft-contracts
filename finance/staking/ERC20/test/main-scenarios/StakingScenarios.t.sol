// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AuxiliaryFunctions.sol";

contract StakingScenarious is AuxiliaryFunctions {
    function test_Staking_BeforeLaunch() external {
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_NoAllowance() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_IncreasedAllowance() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);
    }

    function test_Staking_InsufficentDeposit() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _increaseAllowance(userOne, 1);
        _stakeTokenWithTest(userOne, 0,  1, true);
    }

    function test_Staking_AmountExceedsTarget() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        _stakeTokenWithAllowance(address(this), 0, stakingContract.checkStakingTarget());

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_NotOpen() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        stakingContract.changePoolAvailabilityStatus(0, ProgramManager.PoolDataType.IS_STAKING_OPEN, false);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_ProgramPaused() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        _performPMActions(address(this), PMActions.PAUSE);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_ProgramResumed() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        _performPMActions(address(this), PMActions.PAUSE);
        _performPMActions(address(this), PMActions.RESUME);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
    }

    function test_Staking_ProgramEnded() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        _performPMActions(address(this), PMActions.END);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }
}