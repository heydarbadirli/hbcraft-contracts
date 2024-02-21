// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../main-test-functions/WithdrawalFunctions.sol";

contract FundManagementScenarios is WithdrawalFunctions {
    function test_RestoreFunds_Restores() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        stakingContract.collectFunds(0, amountToStake);

        _increaseAllowance(address(this), amountToStake);
        stakingContract.restoreFunds(0, amountToStake);
    }

    function test_CollectFunds_NotEnoughFundsInThePool() external {
        _addPool(address(this), false);
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, amountToStake);

        stakingContract.collectFunds(0, amountToStake);
        vm.expectRevert();
        stakingContract.collectFunds(0, amountToStake);
    }

    function test_RestoreFunds_NotEnoughFundsInThePool() external {
        _addPool(address(this), false);
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 1, amountToStake);

        stakingContract.collectFunds(0, amountToStake);

        _withdrawTokenWithTest(userOne, 0, 0, true, true);
    }
}
