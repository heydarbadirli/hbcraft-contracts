// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../main-test-functions/WithdrawalFunctions.sol";

contract WithdrawalScenarious is WithdrawalFunctions {
    function test_LockedWithdrawal() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _withdrawTokenWithTest(userOne, 0, 0, true, true);
    }

    function test_FlexibleWithdrawal() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        _withdrawTokenWithTest(userOne, 1, 0, false, true);
    }

    function test_WithdrawalNotOpen() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        stakingContract.changePoolAvailabilityStatus(1, ProgramManager.PoolDataType.IS_WITHDRAWAL_OPEN, false);

        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        _withdrawTokenWithTest(userOne, 1, 0, true, true);
    }
    
    function test_Withdrawal_NotEnoughFundsInThePool() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        stakingContract.collectFunds(1, amountToStake);

        _withdrawTokenWithTest(userOne, 1, 0, true, true);
    }

    function test_DoubleWithdraw() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, amountToStake * 2);

        _withdrawTokenWithTest(userOne, 1, 2, false, true);
        _withdrawTokenWithTest(userOne, 1, 2, true, true);
    }

    function test_WithdrawAll() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, 20);

        _withdrawTokenWithTest(userOne, 1, 9999, false, true);
    }

    function test_Withdrawal_WithInterest() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 1, 100);

        _increaseAllowance(address(this), 1000);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _withdrawTokenWithTest(userOne, 1, 0, false, true);
    }

    function test_Withdrawal_AllWithInterest() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        vm.warp(1706809873);
        for(uint256 times = 0; times < 3; times++){
            _stakeTokenWithAllowance(userOne, 1, 100);
        }

        _increaseAllowance(address(this), 1000);
        stakingContract.provideInterest(1000);

        vm.warp(1738401000);
        _withdrawTokenWithTest(userOne, 1, 9999, false, true);
    }

    function test_Withdrawal_InterestClaimNotOpen() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        stakingContract.changePoolAvailabilityStatus(1, ProgramManager.PoolDataType.IS_INTEREST_CLAIM_OPEN, false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 1, amountToStake);

        _increaseAllowance(address(this), 1000);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _withdrawTokenWithTest(userOne, 1, 0, false, false);
    }
}