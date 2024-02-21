// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./TestSetUp.t.sol";

contract ReadFunctions is TestSetUp {
    function _getTotalStaked(uint256 poolID) internal view returns (uint256) {
        return stakingContract.checkTotalStaked(poolID);
    }

    function _getTotalStakedBy(address userAddress, uint256 poolID) internal view returns (uint256) {
        return stakingContract.checkStakedAmountBy(userAddress, poolID);
    }

    function _getTotalWithdrawn(uint256 poolID) internal view returns (uint256) {
        return stakingContract.checkTotalWithdrawn(poolID);
    }

    function _getTotalWithdrawnBy(address userAddress, uint256 poolID) internal view returns (uint256) {
        return stakingContract.checkWithdrawnAmountBy(userAddress, poolID);
    }

    function _getUserDepositCount(address userAddress, uint256 poolID) internal view returns (uint256) {
        return stakingContract.checkDepositCountOfAddress(userAddress, poolID);
    }

    function _getTokenBalance(address userAddress) internal view returns (uint256) {
        return myToken.balanceOf(userAddress);
    }

    function _getCurrentData(address userAddress, uint256 _poolID) internal view returns (uint256[] memory) {
        uint256[] memory data = new uint256[](4);
        data[0] = _getTotalStaked(_poolID);
        data[1] = _getTokenBalance(userAddress);
        data[2] = _getTotalStakedBy(userAddress, _poolID);
        data[3] = _getTokenBalance(address(stakingContract));
        return data;
    }
}
