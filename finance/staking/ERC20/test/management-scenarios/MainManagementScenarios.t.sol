// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract MainManagementScenarios is AuxiliaryFunctions {
    // ======================================
    // =      Program Management Test       =
    // ======================================
    function test_ProgramManagement_TransferOwnership() external {
        vm.startPrank(contractAdmin);
        vm.expectRevert();
        stakingContract.transferOwnership(userOne);
        vm.stopPrank();

        vm.startPrank(userOne);
        vm.expectRevert();
        stakingContract.transferOwnership(userTwo);
        vm.stopPrank();

        assertEq(stakingContract.contractOwner(), address(this));

        stakingContract.transferOwnership(userOne);
        assertEq(stakingContract.contractOwner(), userOne);
    }

    function test_ProgramManagement_AddRemoveAdmin() external {
        assertEq(stakingContract.contractAdmins(contractAdmin), true);

        stakingContract.removeContractAdmin(contractAdmin);
        assertEq(stakingContract.contractAdmins(contractAdmin), false);
    }

    function test_ProgramManagement_PoolCount(uint8 x) external {
        for (uint8 No; No < x; No++) {
            _addPool(address(this), true);
        }

        assertEq(x, stakingContract.checkPoolCount());
    }

    function test_ProgramManagement_AddEndPool() external {
        vm.warp(1706809873);
        for (uint8 No = 0; No < 10; No++) {
            _addPool(address(this), true);
        }

        vm.warp(1738401000);
        for (uint8 No = 0; No < 10; No++) {
            if (No <= 4 || No >= 7) _endPool(address(this), No);
        }

        vm.warp(1738402000);
        for (uint8 No; No < 10; No++) {
            if (No <= 4 || No >= 7) {
                assertTrue(stakingContract.checkIfPoolEnded(No));
                assertFalse(stakingContract.checkIfStakingOpen(No));
                assertTrue(stakingContract.checkIfWithdrawalOpen(No));
                assertTrue(stakingContract.checkIfInterestClaimOpen(No));
            } else {
                assertFalse(stakingContract.checkIfPoolEnded(No));
                assertTrue(stakingContract.checkIfStakingOpen(No));
                assertFalse(stakingContract.checkIfWithdrawalOpen(No));
                assertTrue(stakingContract.checkIfInterestClaimOpen(No));
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
        assertEq(stakingContract.checkInterestProvidedBy(contractAdmin), amountToProvide);
        vm.expectRevert();
        stakingContract.collectInterestPoolFunds(amountToProvide);
        vm.stopPrank();
        stakingContract.collectInterestPoolFunds(amountToProvide);
    }

    function test_InterestManagement_NotEnoughFundsInTheInterestPool() external {
        _increaseAllowance(address(this), amountToProvide);

        stakingContract.provideInterest(amountToProvide);
        stakingContract.collectInterestPoolFunds(amountToProvide);

        vm.expectRevert();
        stakingContract.collectInterestPoolFunds(amountToProvide);
    }
}
