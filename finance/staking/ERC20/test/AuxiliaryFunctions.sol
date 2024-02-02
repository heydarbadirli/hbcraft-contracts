// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReadFunctions.sol";

contract AuxiliaryFunctions is ReadFunctions {
    // ======================================
    // =  Contract Intereaction Functions   =
    // ======================================
    function _performPMActions(address userAddress, PMActions actionType) internal {
        if (userAddress != address(this)) {vm.startPrank(userAddress);}

        if (actionType == PMActions.LAUNCH){
            stakingContract.launchDefault([_lockedAPY, _flexibleAPY]);
        } else if (actionType == PMActions.PAUSE){
            stakingContract.pauseProgram();
        } else if (actionType == PMActions.RESUME){
            stakingContract.resumeProgram();
        } else if (actionType == PMActions.END){
            stakingContract.endProgram();
        }

        if (userAddress != address(this)) {vm.stopPrank();}
    }

    function _increaseAllowance(address userAddress, uint256 tokenAmount) internal {
        if (userAddress != address(this)) {vm.startPrank(userAddress);}

        myToken.increaseAllowance(address(stakingContract), tokenAmount * myTokenDecimals);

        if (userAddress != address(this)) {vm.stopPrank();}
    }

    function _stakeTokenWithTest(address userAddress, uint256 _poolID, uint256 tokenAmount, bool ifRevertExpected) internal {
        if (userAddress != address(this)) {vm.startPrank(userAddress);}

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.stakeToken(_poolID, tokenAmount);
        } else {
            uint256[] memory currentData = _getCurrentData(userAddress, _poolID, false);
            uint256 userDepositCountBefore = _getUserDepositCount(userAddress, _poolID);

            uint256[] memory expectedData = new uint256[](4);
            expectedData[0] = currentData[0] + tokenAmount;
            expectedData[1] = currentData[1] - tokenAmount;
            expectedData[2] = currentData[2] + tokenAmount;
            expectedData[3] = currentData[3] + tokenAmount;

            stakingContract.stakeToken(_poolID, tokenAmount);

            currentData = _getCurrentData(userAddress, _poolID, false);

            assertEq(currentData[0], expectedData[0]);
            assertEq(currentData[1], expectedData[1]);
            assertEq(currentData[2], expectedData[2]);
            assertEq(currentData[3], expectedData[3]);
            assertEq(_getUserDepositCount(userAddress, _poolID), userDepositCountBefore + 1);
        }

        if (userAddress != address(this)) {vm.stopPrank();}
    }

    function _stakeTokenWithAllowance(address userAddress, uint256 _poolID, uint256 tokenAmount) internal {
        _increaseAllowance(userAddress, tokenAmount);
        _stakeTokenWithTest(userAddress, _poolID, tokenAmount, false);
    }
}
