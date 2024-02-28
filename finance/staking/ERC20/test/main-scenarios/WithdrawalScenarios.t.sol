// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../main-test-functions/WithdrawalFunctions.sol";

contract WithdrawalScenarious is WithdrawalFunctions {
    function test_Withdrawal_Locked() external {
        _addPool(address(this), true);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _withdrawTokenWithTest(userOne, 0, 0, true, true);
    }

    function test_Withdrawal_Flexible() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _withdrawTokenWithTest(userOne, 0, 0, false, true);
    }

    function test_Withdrawal_MultiplePools() external {
        vm.warp(1706809873);

        uint256 howManyTimes = 10;
        _tryMultiUserMultiStake(howManyTimes, true);
        _tryMultiUserMultiStake(howManyTimes, false);
        _tryMultiUserMultiStake(howManyTimes, false);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);

        for (uint256 No; No < howManyTimes; No++) {
            console.log(stakingContract.checkTotalClaimableInterest(No));
            for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
                for (uint256 timesStaked; timesStaked < 3; timesStaked++) {
                    _withdrawTokenWithTest(addressList[userNo], No, timesStaked, false, true);
                }
            }
        }
    }

    function test_Withdrawal_NotOpen() external {
        _addPool(address(this), false);
        stakingContract.changePoolAvailabilityStatus(0, 1, false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _withdrawTokenWithTest(userOne, 0, 0, true, true);
    }

    function test_Withdrawal_NotEnoughFundsInThePool() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        stakingContract.collectFunds(0, amountToStake);

        _withdrawTokenWithTest(userOne, 0, 0, true, true);
    }

    function test_Withdrawal_DoubleWithdrawal() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake * 2);

        _withdrawTokenWithTest(userOne, 0, 2, false, true);
        _withdrawTokenWithTest(userOne, 0, 2, true, true);
    }

    function test_Withdraw_WithdrawAll() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, 20 * myTokenDecimals);

        _withdrawTokenWithTest(userOne, 0, 9999, false, true);
    }

    function test_Withdrawal_WithInterest() external {
        _addPool(address(this), false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, 100 * myTokenDecimals);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _withdrawTokenWithTest(userOne, 0, 0, false, true);
    }

    function test_Withdrawal_AllWithInterest() external {
        _addPool(address(this), false);

        vm.warp(1706809873);
        for (uint256 times = 0; times < 3; times++) {
            _stakeTokenWithAllowance(userOne, 0, 100 * myTokenDecimals);
        }

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _withdrawTokenWithTest(userOne, 0, 9999, false, true);
    }

    function test_Withdrawal_InterestClaimNotOpen() external {
        _addPool(address(this), false);
        stakingContract.changePoolAvailabilityStatus(0, 2, false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1738401000);
        _withdrawTokenWithTest(userOne, 0, 0, false, false);
    }

    function test_Withdrawal_AfterPoolEnds() external {
        _addPool(address(this), true);
        _addPool(address(this), true);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, amountToStake);

        vm.warp(1738401000);
        _endPool(address(this), 0);

        assertTrue(stakingContract.checkIfWithdrawalOpen(0));
        assertFalse(stakingContract.checkIfWithdrawalOpen(1));

        assertTrue(stakingContract.checkIfInterestClaimOpen(0));
        assertTrue(stakingContract.checkIfInterestClaimOpen(1));

        assertTrue(stakingContract.checkIfStakingOpen(1));
        assertFalse(stakingContract.checkIfStakingOpen(0));

        _withdrawTokenWithTest(userOne, 0, 0, false, true);
        _withdrawTokenWithTest(userOne, 1, 0, true, true);
        assertEq(stakingContract.checkClaimableInterestBy(userOne, 0, 0), 0);

        vm.warp(1738402000);
        _claimInterestWithTest(userOne, 0, 0, true);

        _endPool(address(this), 1);
        _claimInterestWithTest(userOne, 1, 0, false);
        assertEq(stakingContract.checkClaimableInterestBy(userOne, 1, 0), 0);
    }

    function test_InterestClaim_DepositWithdrawn() external {
        _addPool(address(this), false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseAllowance(address(this), amountToProvide);
        stakingContract.provideInterest(amountToProvide);

        vm.warp(1707000000);
        _withdrawTokenWithTest(userOne, 0, 0, false, true);
        assertEq(stakingContract.checkClaimableInterestBy(userOne, 0, 0), 0, "no interest");

        vm.warp(1708000000);
        assertEq(stakingContract.checkClaimableInterestBy(userOne, 0, 0), 0, "no interest");
        _claimInterestWithTest(userOne, 0, 0, true);
    }

    function test_WithdrawAll_AfterWithdrawal() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _withdrawTokenWithTest(userOne, 0, 1, false, true);
        console.log(stakingContract.checkStakedAmountBy(userOne, 0));
        console.log(stakingContract.checkWithdrawnAmountBy(userOne, 0));
        console.log(stakingContract.checkTotalStaked(0));
        //        _withdrawTokenWithTest(userOne, 0, 0, false, true);
        _withdrawTokenWithTest(userOne, 0, 9999, false, true);
    }

    function test_Withdrawal_AfterCollectFunds() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        stakingContract.collectFunds(0, 2 * amountToStake);
        myToken.increaseAllowance(address(stakingContract), 2 * amountToStake);
        stakingContract.restoreFunds(0, 2 * amountToStake);

        _withdrawTokenWithTest(userOne, 0, 0, false, true);
        _withdrawTokenWithTest(userOne, 0, 1, false, true);
    }
}
