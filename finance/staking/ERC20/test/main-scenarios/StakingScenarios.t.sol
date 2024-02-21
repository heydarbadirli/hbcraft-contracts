// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract StakingScenarious is AuxiliaryFunctions {
    function test_Staking_BeforeLaunch() external {
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_NoAllowance() external {
        _addPool(address(this), true);

        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_IncreasedAllowance() external {
        _addPool(address(this), true);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);
    }

    function test_Staking_MultiplePools() external {
        _tryMultiUserMultiStake(10, true);
    }

    function test_Staking_InsufficentDeposit() external {
        _addPool(address(this), true);

        _increaseAllowance(userOne, 1);
        _stakeTokenWithTest(userOne, 0, 1, true);
    }

    function test_Staking_AmountExceedsTarget() external {
        _addPool(address(this), true);
        _addPool(address(this), true);
        _stakeTokenWithAllowance(userThree, 0, stakingContract.checkStakingTarget(0));

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);
    }

    function test_Staking_NotOpen() external {
        _addPool(address(this), true);
        stakingContract.changePoolAvailabilityStatus(0, 0, false);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_ProgramPaused() external {
        _addPool(address(this), true);
        _performPMActions(address(this), PMActions.PAUSE);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_ProgramResumed() external {
        _addPool(address(this), true);
        _performPMActions(address(this), PMActions.PAUSE);
        _performPMActions(address(this), PMActions.RESUME);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
    }

    function test_Staking_ProgramEnded() external {
        _addPool(address(this), true);
        _addPool(address(this), true);
        _endPool(address(this), 0);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }
}
