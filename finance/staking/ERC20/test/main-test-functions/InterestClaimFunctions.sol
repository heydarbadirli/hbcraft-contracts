// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AuxiliaryFunctions.sol";

contract InterestClaimFunctions is AuxiliaryFunctions {
    function _trackInterestClaim(address userAddress, uint256 _poolID, uint256 _depositNo) internal view
    returns (uint256) {
        uint256 userBalanceBefore = _getTokenBalance(userAddress, true);
        uint256 _claimableInterest = stakingContract.checkClaimableInterest(userAddress, _poolID, _depositNo, true);
        uint256 userBalanceAfter = userBalanceBefore + _claimableInterest;

        return userBalanceAfter;
    }

    function _testInterestClaim(address userAddress, uint256 _poolID, uint256 _depositNo, uint256 userBalanceAfter) internal {
        assertEq(stakingContract.checkClaimableInterest(userAddress, _poolID, _depositNo, true), 0);
        assertEq(_getTokenBalance(userAddress, true), userBalanceAfter);
    }

    function _claimInterestWithTest(address userAddress, uint256 _poolID, uint256 _depositNo, bool ifRevertExpected) internal {
        if (userAddress != address(this)) {vm.startPrank(userAddress);}

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.claimInterest(_poolID, _depositNo);
        } else {
            uint256 userBalanceAfter = _trackInterestClaim(userAddress, _poolID, _depositNo);

            stakingContract.claimInterest(_poolID, _depositNo);

            _testInterestClaim(userAddress, _poolID, _depositNo, userBalanceAfter);
        }

        if (userAddress != address(this)) {vm.stopPrank();}
    }

    function _claimAllInterestWithTest(address userAddress, uint256 _poolID, bool ifRevertExpected) internal {
        if (userAddress != address(this)) {vm.startPrank(userAddress);}

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.claimAllInterest(_poolID);
        } else {
            uint256 userBalanceBefore = _getTokenBalance(userAddress, true);

            uint256 _claimableInterest;
            uint256 depositCount = stakingContract.checkDepositCountOfAddress(userAddress)[_poolID];
            for(uint256 _depositNo = 0; _depositNo < depositCount; _depositNo++){
                _claimableInterest += stakingContract.checkClaimableInterest(userAddress, _poolID, _depositNo, true);
            }

            uint256 userBalanceAfter = userBalanceBefore + _claimableInterest;

            stakingContract.claimAllInterest(_poolID);

            uint256 newclaimableInterest;
            depositCount = stakingContract.checkDepositCountOfAddress(userAddress)[_poolID];
            for(uint256 _depositNo = 0; _depositNo < depositCount; _depositNo++){
                newclaimableInterest += stakingContract.checkClaimableInterest(userAddress, _poolID, _depositNo, true);
            }

            assertEq(newclaimableInterest, 0);
            assertEq(_getTokenBalance(userAddress, true), userBalanceAfter);
        }

        if (userAddress != address(this)) {vm.stopPrank();}
    }    
}