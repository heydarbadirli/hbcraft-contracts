// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../main-test-functions/InterestClaimFunctions.sol";

contract InterestClaimScenarios is InterestClaimFunctions {
    function test_InterestClaim() external {
        _addPool(address(this), true);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _claimInterestWithTest(userOne, 0, 0, false);
    }

    function test_InterestClaim_ClaimAll() external {
        _addPool(address(this), true);

        vm.warp(1706809873);
        for (uint256 times = 0; times < 3; times++) {
            _stakeTokenWithAllowance(userOne, 0, amountToStake);
        }

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _claimAllInterestWithTest(userOne, 0, false);
    }

    function test_InterestClaim_NotEnoughFundsInTheInterestPool() external {
        _addPool(address(this), true);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        vm.warp(1738401000);
        _claimInterestWithTest(userOne, 0, 0, true);
    }

    function test_InterestClaim_NothingToClaim() external {
        _addPool(address(this), true);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        _claimInterestWithTest(userOne, 0, 0, true);
    }

    function test_InterestClaim_NotOpen() external {
        _addPool(address(this), true);
        stakingContract.changePoolAvailabilityStatus(0, 2, false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _claimInterestWithTest(userOne, 0, 0, true);
    }

    function test_InterestClaim_DoubleDeposit() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        skip(2 days);
        uint256 expectedInterests = stakingContract.checkTotalClaimableInterestBy(userOne, 0);
        assertEq(stakingContract.checkTotalClaimableInterest(0), expectedInterests, "wrong interest 1");
        assertEq(stakingContract.checkGeneratedInterestDailyTotal(0, true), expectedInterests / 2, "wrong interest 2");
        assertEq(stakingContract.checkGeneratedInterestDailyTotal(0, false), expectedInterests / 2, "wrong interest 3");
    }
}
