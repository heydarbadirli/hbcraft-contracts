// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AuxiliaryFunctions.sol";

contract AccessControlTest is AuxiliaryFunctions {
    /*function test_AccessControl_UserTier() external {
        assertEq(uint256(stakingContract.checkYourAccessTier()), 2);

        vm.startPrank(contractAdmin);
        assertEq(uint256(stakingContract.checkYourAccessTier()), 1);
        vm.stopPrank();

        vm.startPrank(userOne);
        assertEq(uint256(stakingContract.checkYourAccessTier()), 0);
        vm.stopPrank();
    }*/

    function _checkAccesControl(address userAddress, PMActions actionType) internal {
        vm.expectRevert();
        _performPMActions(userAddress, actionType);
    }

    function test_AccessControl_RevertProgramControlAccess() external {
        for(uint256 userNo = 0; userNo < addressList.length; userNo++){
            for(uint256 actionNo; actionNo < 2; actionNo++){
                _checkAccesControl(addressList[userNo], PMActions(actionNo));
            }
        }
    }

    function test_AccessControl_RevertAddPool() external {
        for(uint256 userNo = 0; userNo < addressList.length; userNo++){
            vm.expectRevert();
            _addPool(addressList[userNo], true);
        }
    }

    function test_AccessControl_RevertAddCustomPool() external {
        for(uint256 userNo = 0; userNo < addressList.length; userNo++){
            vm.expectRevert();
            _addCustomPool(addressList[userNo], true);
        }
    }

    function test_AccessControl_RevertEndPool() external {
        _addPool(address(this), true);

        for(uint256 userNo = 0; userNo < addressList.length; userNo++){
            vm.expectRevert();
            _endPool(addressList[userNo], 0);
        }
    }
}
