// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../main-test-functions/InterestClaimFunctions.sol";

contract InterestClaimScenarios is InterestClaimFunctions {

    function test_InterestClaim() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), 1000);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _claimInterestWithTest(userOne, 0, 0, false);
    }

    function test_ClaimAllInterest() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        vm.warp(1706809873);
        for(uint256 times = 0; times < 3; times++){
            _stakeTokenWithAllowance(userOne, 0, amountToStake);
        }

        _increaseAllowance(address(this), 1000);
        stakingContract.provideInterest(1000);

        vm.warp(1738401000);
        _claimAllInterestWithTest(userOne, 0, false);
    }

    function test_InterestClaim_NotEnoughFundsInTheInterestPool() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        vm.warp(1738401000);
        _claimInterestWithTest(userOne, 0, 0, true);
    }

    function test_InterestClaim_NothingToClaim() external {
        _performPMActions(address(this), PMActions.LAUNCH);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        _claimInterestWithTest(userOne, 0, 0, true);
    }

    function test_InterestClaim_NotOpen() external {
        _performPMActions(address(this), PMActions.LAUNCH);
        stakingContract.changePoolAvailabilityStatus(0, ProgramManager.PoolDataType.IS_INTEREST_CLAIM_OPEN, false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), 1000);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _claimInterestWithTest(userOne, 0, 0, true);
    }
}
