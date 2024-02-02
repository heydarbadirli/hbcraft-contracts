// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "../ComplianceCheck.sol";


contract ReadFunctions is ComplianceCheck {
    // ======================================
    // =  Functoins to check program data   =
    // ======================================
    function checkStakingTarget() external view
    returns (uint256) {
        return stakingTarget / tokenDecimals;
    }

    function checkDefaultMinimumDeposit() external view
    onlyAdmins
    returns (uint256) {
        return defaultMinimumDeposit / tokenDecimals;
    }

    function checkInterestPool() external view
    onlyAdmins
    returns (uint256) {
        return interestPool / tokenDecimals;
    }

    function checkInterestProvidedByAddress(address userAddress) external view
    onlyAdmins
    returns (uint256) {
        return interestProviderList[userAddress] / tokenDecimals;
    }

    function checkInterestCollectedByAddress(address userAddress) external view
    onlyAdmins
    returns (uint256) {
        return interestCollectorList[userAddress] / tokenDecimals;
    }


    // ======================================
    // =Functions to check stakingPool data =
    // ======================================
    function _getPoolAPYDataList() private view
    ifProgramLaunched
    returns (uint256[] memory) {
        uint256 length = stakingPoolList.length;
        uint256[] memory propertyList = new uint256[](length);

        for (uint256 poolNumber = 0; poolNumber < length; poolNumber++) {
            propertyList[poolNumber] = stakingPoolList[poolNumber].APY / tokenDecimals;
        }
        return propertyList;
    }

    function _getPoolTypeList() private view
    ifProgramLaunched
    returns (PoolType[] memory) {
        uint256 length = stakingPoolList.length;
        PoolType[] memory propertyList = new PoolType[](length);

        for (uint256 poolNumber = 0; poolNumber < length; poolNumber++) {
            propertyList[poolNumber] = stakingPoolList[poolNumber].poolType;
        }
        return propertyList;
    }

    function _getPoolAvailabilityDataList(PoolDataType dataType) private view
    ifProgramLaunched
    returns (bool[] memory) {
        uint256 length = stakingPoolList.length;
        bool[] memory propertyList = new bool[](length);

        for (uint256 poolNumber = 0; poolNumber < length; poolNumber++) {
            if (dataType == PoolDataType.IS_STAKING_OPEN){
                propertyList[poolNumber] = stakingPoolList[poolNumber].isStakingOpen;
            } else if (dataType == PoolDataType.IS_WITHDRAWAL_OPEN){
                propertyList[poolNumber] = stakingPoolList[poolNumber].isWithdrawalOpen;
            } else if (dataType == PoolDataType.IS_INTEREST_CLAIM_OPEN){
                propertyList[poolNumber] = stakingPoolList[poolNumber].isInterestClaimOpen;
            }
        }
        return propertyList;
    }

    function checkPoolType() external view
    returns (PoolType[] memory) {
        return _getPoolTypeList();
    }

    function checkAPY() external view
    returns (uint256[] memory){
        return _getPoolAPYDataList();
    }

    function checkIfStakingOpen() external view 
    returns (bool[] memory){
        return _getPoolAvailabilityDataList(PoolDataType.IS_STAKING_OPEN);
    }

    function checkIfWithdrawalOpen() external view
    returns (bool[] memory){
        return _getPoolAvailabilityDataList(PoolDataType.IS_WITHDRAWAL_OPEN);
    }

    function checkIfInterestClaimOpen() external view
    returns (bool[] memory){
        return _getPoolAvailabilityDataList(PoolDataType.IS_WITHDRAWAL_OPEN);
    }

    function _getPoolTotalDataList(DataType dataType) private view
    ifProgramLaunched
    returns (uint256[] memory) {
        uint256 length = stakingPoolList.length;
        uint256[] memory propertyList = new uint256[](length);

        for (uint256 poolNumber = 0; poolNumber < length; poolNumber++) {
            propertyList[poolNumber] = stakingPoolList[poolNumber].totalList[dataType] / tokenDecimals;
            }

        return propertyList;
    }

    function checkTotalStaked() public view
    returns (uint256[] memory){
        return _getPoolTotalDataList(DataType.STAKED);
    }

    function checkTotalWithdrew() external view
    onlyAdmins
    returns (uint256[] memory){
        return _getPoolTotalDataList(DataType.WITHDREW);
    }

    function checkTotalInterestClaimed() external view
    onlyAdmins
    returns (uint256[] memory){
        return _getPoolTotalDataList(DataType.INTEREST_CLAIMED);
    }

    function checkTotalFundCollected() external view
    onlyAdmins
    returns (uint256[] memory){
        return _getPoolTotalDataList(DataType.FUNDS_COLLECTED);
    }


    // ======================================
    // =    Functoins to check user data    =
    // ======================================
    function _getUserDataList(DataType dataType, address userAddress) private view
    ifProgramLaunched
    returns (uint256[] memory) {
        uint256 length = stakingPoolList.length;
        uint256[] memory propertyList = new uint256[](length);

        for (uint256 poolNumber = 0; poolNumber < length; poolNumber++) {
            if (dataType == DataType.STAKED){
                propertyList[poolNumber] = stakingPoolList[poolNumber].stakerList[userAddress] / tokenDecimals;
            } else if (dataType == DataType.WITHDREW){
                propertyList[poolNumber] = stakingPoolList[poolNumber].withdrawerList[userAddress] / tokenDecimals;
            } else if (dataType == DataType.INTEREST_CLAIMED){
                propertyList[poolNumber] = stakingPoolList[poolNumber].interestClaimerList[userAddress] / tokenDecimals;
            } else if (dataType == DataType.FUNDS_COLLECTED){
                propertyList[poolNumber] = stakingPoolList[poolNumber].fundCollectorList[userAddress] / tokenDecimals;
            } else if (dataType == DataType.DEPOSIT_COUNT){
                propertyList[poolNumber] = stakingPoolList[poolNumber].stakerDepositList[userAddress].length;
            }
            }
        return propertyList;
    }
   
    function checkStakedAmountByAddress(address addressInput) external view
    personalDataAccess(addressInput)
    returns (uint256[] memory){
        return _getUserDataList(DataType.STAKED, addressInput);
    }

    function checkWithdrewAmountByAddress(address addressInput) external view
    personalDataAccess(addressInput)
    returns (uint256[] memory){
        return _getUserDataList(DataType.WITHDREW, addressInput);
    }

    function checkInterestClaimedByAddress(address addressInput) external view
    personalDataAccess(addressInput)
    returns (uint256[] memory){
        return _getUserDataList(DataType.INTEREST_CLAIMED, addressInput);
    }

    function checkCollectedFundsByAddress(address addressInput) external view
    onlyAdmins
    returns (uint256[] memory){
        return _getUserDataList(DataType.FUNDS_COLLECTED, addressInput);
    }

    function checkDepositCountOfAddress(address addressInput) external view
    personalDataAccess(addressInput)
    returns (uint256[] memory){
        return _getUserDataList(DataType.DEPOSIT_COUNT, addressInput);
    }

    function checkYourAccessTier() external view
    returns(AccessTier) {
        if (msg.sender == contractOwner){
            return AccessTier.OWNER;
        } else if (contractAdmins[msg.sender]) {
            return AccessTier.ADMIN;
        } else {
            return AccessTier.USER;
        }
    }
}