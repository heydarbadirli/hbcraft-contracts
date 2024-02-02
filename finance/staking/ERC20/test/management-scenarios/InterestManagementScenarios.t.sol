
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AuxiliaryFunctions.sol";

contract InterestManagementScenarios is AuxiliaryFunctions {
    function test_ProvideInterest() external {
        _increaseAllowance(contractAdmin, amountToProvide);

        vm.startPrank(contractAdmin);
        stakingContract.provideInterest(amountToProvide);
        vm.stopPrank();
    }

    function test_CollectInterestPoolFunds() external {
        _increaseAllowance(contractAdmin, amountToProvide);

        vm.startPrank(contractAdmin);
        stakingContract.provideInterest(amountToProvide);
        stakingContract.collectInterestPoolFunds(amountToProvide);
        vm.stopPrank();
    }

    function test_NotEnoughFundsInTheInterestPool() external {
        _increaseAllowance(contractAdmin, amountToProvide);
        
        vm.startPrank(contractAdmin);
        stakingContract.provideInterest(amountToProvide);
        stakingContract.collectInterestPoolFunds(amountToProvide);
        
        vm.expectRevert();
        stakingContract.collectInterestPoolFunds(amountToProvide);
        vm.stopPrank();
    }
}