
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AuxiliaryFunctions.sol";

contract MainManagementScenarios is AuxiliaryFunctions {
    // ======================================
    // =      Program Management Test       =
    // ======================================
    function test_ProgramManagement_AddRemoveAdmin() external {
        assertEq(stakingContract.contractAdmins(contractAdmin), true);

        stakingContract.removeContractAdmin(contractAdmin);
        assertEq(stakingContract.contractAdmins(contractAdmin), false);
    }

    function test_ProgramManagement_PoolCount(uint8 x) external {
        for(uint8 No; No < x; No++){
            _addPool(address(this), true);
        }

        assertEq(x, stakingContract.checkPoolCount());
    }

    function test_ProgramManagement_AddEndPool() external {
        vm.warp(1706809873);
        for(uint8 No = 0; No < 10; No++){
            _addPool(address(this), true);
        }

        vm.warp(1738401000);
        for(uint8 No = 0; No < 5; No++){
            _endPool(address(this), No);
        }

        vm.warp(1738402000);
        for(uint8 No; No < 10; No++){
            if (No <= 4){
                assertTrue(stakingContract.checkIfPoolEnded(No));
            } else {
                assertFalse(stakingContract.checkIfPoolEnded(No));
            }
        }

        vm.warp(1738403000);
        for(uint8 No = 7; No < 10; No++){
            _endPool(address(this), No);
        }

        vm.warp(1738404000);
        for(uint8 No; No < 10; No++){
            if (No <= 4){
                assertTrue(stakingContract.checkIfPoolEnded(No));
            } else if (No > 4 && No < 7) {
                assertFalse(stakingContract.checkIfPoolEnded(No));
            } else if (No >= 7) {
                assertTrue(stakingContract.checkIfPoolEnded(No));
            }
        }
    }

    function test_ProgramManagement_IncorrectConfirmationCode() external {
        _addPool(address(this), true);
        vm.expectRevert();
        stakingContract.endStakingPool(0, 255);
    }

    // ======================================
    // =      Interest Management Test      =
    // ======================================
    function test_InterestManagement_ProvideInterest() external {
        _increaseAllowance(contractAdmin, amountToProvide);

        vm.startPrank(contractAdmin);
        stakingContract.provideInterest(amountToProvide);
        vm.stopPrank();
    }

    function test_InterestManagement_CollectInterestPoolFunds() external {
        _increaseAllowance(contractAdmin, amountToProvide);

        vm.startPrank(contractAdmin);
        stakingContract.provideInterest(amountToProvide);
        stakingContract.collectInterestPoolFunds(amountToProvide);
        vm.stopPrank();
    }

    function test_InterestManagement_NotEnoughFundsInTheInterestPool() external {
        _increaseAllowance(contractAdmin, amountToProvide);
        
        vm.startPrank(contractAdmin);
        stakingContract.provideInterest(amountToProvide);
        stakingContract.collectInterestPoolFunds(amountToProvide);
        
        vm.expectRevert();
        stakingContract.collectInterestPoolFunds(amountToProvide);
        vm.stopPrank();
    }
}