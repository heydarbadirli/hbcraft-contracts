// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract InterestClaimFunctions is AuxiliaryFunctions {
    function _trackInterestClaim(address userAddress, uint256 _poolID, uint256 _depositNo)
        internal
        view
        returns (uint256)
    {
        uint256 userBalanceBefore = _getTokenBalance(userAddress);
        uint256 _claimableInterest = stakingContract.checkClaimableInterestBy(userAddress, _poolID, _depositNo);
        uint256 userBalanceAfter = userBalanceBefore + _claimableInterest;

        return userBalanceAfter;
    }

    function _testInterestClaim(address userAddress, uint256 _poolID, uint256 _depositNo, uint256 userBalanceAfter)
        internal
    {
        assertEq(stakingContract.checkClaimableInterestBy(userAddress, _poolID, _depositNo), 0);
        assertEq(_getTokenBalance(userAddress), userBalanceAfter);
    }

    function _claimInterestWithTest(address userAddress, uint256 _poolID, uint256 _depositNo, bool ifRevertExpected)
        internal
    {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.claimInterest(_poolID, _depositNo);
        } else {
            uint256 userBalanceAfter = _trackInterestClaim(userAddress, _poolID, _depositNo);

            stakingContract.claimInterest(_poolID, _depositNo);

            _testInterestClaim(userAddress, _poolID, _depositNo, userBalanceAfter);
        }

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _claimAllInterestWithTest(address userAddress, uint256 _poolID, bool ifRevertExpected) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.claimAllInterest(_poolID);
        } else {
            uint256 userBalanceBefore = _getTokenBalance(userAddress);

            uint256 _claimableInterest;
            uint256 depositCount = stakingContract.checkDepositCountOfAddress(userAddress, _poolID);
            for (uint256 _depositNo = 0; _depositNo < depositCount; _depositNo++) {
                _claimableInterest += stakingContract.checkClaimableInterestBy(userAddress, _poolID, _depositNo);
            }

            uint256 userBalanceAfter = userBalanceBefore + _claimableInterest;

            stakingContract.claimAllInterest(_poolID);

            uint256 newclaimableInterest;
            depositCount = stakingContract.checkDepositCountOfAddress(userAddress, _poolID);
            for (uint256 _depositNo = 0; _depositNo < depositCount; _depositNo++) {
                newclaimableInterest += stakingContract.checkClaimableInterestBy(userAddress, _poolID, _depositNo);
            }

            assertEq(newclaimableInterest, 0);
            assertEq(_getTokenBalance(userAddress), userBalanceAfter);
        }

        if (userAddress != address(this)) vm.stopPrank();
    }
}
