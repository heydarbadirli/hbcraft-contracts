// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AuxiliaryFunctions.sol";

contract AccessControlTest is AuxiliaryFunctions {
    function test_UserTier() external {
        assertEq(uint256(stakingContract.checkYourAccessTier()), 2);

        vm.startPrank(contractAdmin);
        assertEq(uint256(stakingContract.checkYourAccessTier()), 1);
        vm.stopPrank();

        vm.startPrank(userOne);
        assertEq(uint256(stakingContract.checkYourAccessTier()), 0);
        vm.stopPrank();
    }

    function _checkAccesControl(address userAddress, PMActions actionType) internal {
        vm.expectRevert();
        _performPMActions(userAddress, actionType);
    }

    function test_RevertProgramControlAccess() external {
        for(uint256 userNo = 0; userNo < addressList.length; userNo++){
            for(uint256 actionNo; actionNo < 4; actionNo++){
                _checkAccesControl(addressList[userNo], PMActions(actionNo));
            }
        }
    }


    // ======================================
    // =      Program Management Test       =
    // ======================================
    function test_AddRemoveAdmin() external {
        assertEq(stakingContract.contractAdmins(contractAdmin), true);

        stakingContract.removeContractAdmin(contractAdmin);
        assertEq(stakingContract.contractAdmins(contractAdmin), false);
    }
}
