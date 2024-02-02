// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "../ComplianceCheck.sol";


contract AdministrativeFunctions is ComplianceCheck {
    // ======================================
    // =     Program Parameter Setters      =
    // ======================================
    function addContractAdmin(address userAddress) external
    onlyContractOwner {
        require(userAddress != msg.sender, "Owner can not be an admin");
        contractAdmins[userAddress] = true;
    }

    function removeContractAdmin(address userAddress) external
    onlyContractOwner {
        contractAdmins[userAddress] = false;
    }

    function setStakingTarget(uint128 newStakingTarget) external
    onlyContractOwner {
        stakingTarget = newStakingTarget * tokenDecimals;
    }

    function setDefaultMinimumDeposit(uint256 newDefaultMinimumDeposit) external
    onlyContractOwner {
        defaultMinimumDeposit = newDefaultMinimumDeposit * tokenDecimals;
    }

    // NOTICE: For testing purposes
    function setProgramEndDate(uint256 dateInTimestamp) external
    onlyContractOwner {
        programEndDate = dateInTimestamp;
    }

    function _addStakingPool(PoolType typeToSet, uint256 minimumDepositToSet, bool stakingAvailabilityStatusToCheck, uint256 APYToSet) private {
        // NOTICE: Adds a new, empty StakingPool instance to the stakingPoolList
        stakingPoolList.push();

        // NOTICE: Accesses the newly created instance at the end of the array to set its properties
        uint256 newIndex = stakingPoolList.length - 1;
        StakingPool storage targetPool = stakingPoolList[newIndex];
        targetPool.poolType = typeToSet; // Set the poolType
        targetPool.minimumDeposit = minimumDepositToSet; // Set the minimumDeposit
        targetPool.isStakingOpen = stakingAvailabilityStatusToCheck; // Set the isStakingOpen
        targetPool.isWithdrawalOpen = (typeToSet == PoolType.LOCKED) ? false : true; // Set the isWithdrawalOpen
        targetPool.isInterestClaimOpen = true; // Set the isInterestClaimOpen
        targetPool.APY = APYToSet; // Set the APY
    }

    function addStakingPool(PoolType typeToSet, uint256 minimumDepositToSet, bool stakingAvailabilityStatusToCheck, uint256 APYToSet) external 
    onlyContractOwner {
        _addStakingPool(typeToSet, minimumDepositToSet * tokenDecimals, stakingAvailabilityStatusToCheck, APYToSet * tokenDecimals);
    }

    // DEV: Changes staking pool availabilty parameters to the predefined parameter settings
    // DEV: The function is used in resumeProgram
    function _resetProgramSettings() private {
        for (uint256 poolNumber = 0; poolNumber < stakingPoolList.length; poolNumber++)
        {
            changePoolAvailabilityStatus(poolNumber, PoolDataType.IS_STAKING_OPEN, true);
            changePoolAvailabilityStatus(poolNumber, PoolDataType.IS_INTEREST_CLAIM_OPEN, true);
            if (stakingPoolList[poolNumber].poolType == PoolType.LOCKED){
                changePoolAvailabilityStatus(poolNumber, PoolDataType.IS_WITHDRAWAL_OPEN, false);
            }
            else {
                changePoolAvailabilityStatus(poolNumber, PoolDataType.IS_WITHDRAWAL_OPEN, true);
            }
        }
    }


    // ======================================
    // =     Program Control Functions      =
    // ======================================
    // DEV: Functions to easily launch, pause or resume the program

    // NOTICE: Adds 2 new, empty StakingPool instances to the stakingPoolList: 1 PoolType.LOCKED, 1 PoolType.FLEXIBLE
    // NOTICE: Sets their minimumDeposit to defaultMinimumDeposit
    // NOTICE: Sets isStakingOpen true for both both
    // NOTICE: Sets isWithdrawalOpen false for the PoolType.LOCKED, true for the PoolType.FLEXIBLE
    function launchDefault(uint256[2] memory lockedAndFlexibleAPY) external
    onlyContractOwner
    ifProgramEnded {
        require((
        lockedAndFlexibleAPY[0] != 0 && lockedAndFlexibleAPY[1] != 0
        ), "APY has to be over 0!");

        _addStakingPool(PoolType.LOCKED, defaultMinimumDeposit, true, lockedAndFlexibleAPY[0] * tokenDecimals);
        _addStakingPool(PoolType.FLEXIBLE, defaultMinimumDeposit, true, lockedAndFlexibleAPY[1] * tokenDecimals);
    }

    // NOTICE: Sets isStakingOpen parameter of all the staking pools to false
    // NOTICE: Sets iisWithdrawalOpen parameter of all the staking pools to false
    function pauseProgram() public
    onlyContractOwner
    ifProgramEnded {
        _changeAllPoolAvailabilityStatus(PoolDataType.IS_STAKING_OPEN, false);
        _changeAllPoolAvailabilityStatus(PoolDataType.IS_WITHDRAWAL_OPEN, false);
        _changeAllPoolAvailabilityStatus(PoolDataType.IS_INTEREST_CLAIM_OPEN, false);
    }

    // NOTICE: Sets isStakingOpen parameter of all the staking pools to true
    // NOTICE: Sets isWithdrawalOpen parameter of all LOCKED staking pools to false
    // NOTICE: Sets isWithdrawalOpen parameter of all FLEXIBLE staking pools to true
    function resumeProgram() public
    onlyContractOwner
    ifProgramEnded {
        _resetProgramSettings();
    }

    // NOTICE: Sets programEndDate to the date and time the function called
    // NOTICE: Sets isStakingOpen parameter of each pool to false
    // NOTICE: Sets isWithDrawal parameter of each pool to true
    function endProgram() external
    onlyContractOwner
    ifProgramEnded {
        _changeAllPoolAvailabilityStatus(PoolDataType.IS_STAKING_OPEN, false);
        _changeAllPoolAvailabilityStatus(PoolDataType.IS_WITHDRAWAL_OPEN, true);
        _changeAllPoolAvailabilityStatus(PoolDataType.IS_INTEREST_CLAIM_OPEN, true);
        programEndDate = block.timestamp;
    }


    // ======================================
    // =       Pool Parameter Setters       =
    // ======================================
    function changePoolAvailabilityStatus(uint256 poolID, PoolDataType parameterToChange, bool valueToAssign) public
    onlyAdmins {
        if (parameterToChange == PoolDataType.IS_STAKING_OPEN){
            stakingPoolList[poolID].isStakingOpen = valueToAssign;
        } else if (parameterToChange == PoolDataType.IS_WITHDRAWAL_OPEN){
            stakingPoolList[poolID].isWithdrawalOpen = valueToAssign;
        } else if (parameterToChange == PoolDataType.IS_INTEREST_CLAIM_OPEN){
            stakingPoolList[poolID].isInterestClaimOpen = valueToAssign;
        }
    }

    function _changeAllPoolAvailabilityStatus(PoolDataType parameterToChange, bool valueToAssign) private {
        for (uint256 poolNumber = 0; poolNumber < stakingPoolList.length; poolNumber++)
        {
            changePoolAvailabilityStatus(poolNumber, parameterToChange, valueToAssign);
        }
    }

    function setPoolAPY (uint256 poolID, uint256 newAPY) public
    onlyContractOwner {
        uint256 APYValueToWei = newAPY * tokenDecimals;
        require(newAPY != stakingPoolList[poolID].APY, "The same as current APY");

        stakingPoolList[poolID].APY = APYValueToWei;
        emit APYUpdated(poolID, newAPY);
    }

    function setPoolMiniumumDeposit(uint256 poolID, uint256 newMinimumDepositAmount) external
    onlyAdmins {
        stakingPoolList[poolID].minimumDeposit = newMinimumDepositAmount * tokenDecimals;
    }


    // ======================================
    // =     FUND MANAGEMENT FUNCTIONS      =
    // ======================================
    // DEV: Collects staked funds from the target StakingPool
    function collectFunds(uint256 poolID, uint256 tokenAmount) external
    nonReentrant
    onlyAdmins
    enoughFundsAvailable(poolID, tokenAmount * tokenDecimals) {
        uint256 amountWithDecimals = tokenAmount * tokenDecimals;
        StakingPool storage targetPool = stakingPoolList[poolID];
        targetPool.fundCollectorList[msg.sender] += amountWithDecimals;
        targetPool.totalList[DataType.FUNDS_COLLECTED] += amountWithDecimals;

        _sendToken(msg.sender, amountWithDecimals);
        emit CollectFunds(msg.sender, poolID, tokenAmount);
    }

    // DEV: Restores funds collected from the target StakingPool
    function restoreFunds(uint256 poolID, uint256 tokenAmount) external
    nonReentrant
    onlyAdmins {
        StakingPool storage targetPool = stakingPoolList[poolID];
        uint256 remainingFundsToRestore = targetPool.totalList[DataType.FUNDS_COLLECTED] - targetPool.totalList[DataType.FUNDS_RESTORED];

        uint256 amountWithDecimals = tokenAmount * tokenDecimals;

        if (amountWithDecimals > remainingFundsToRestore){
            revert RestorationExceedsCollected(tokenAmount, remainingFundsToRestore);
        }

        _receiveToken(amountWithDecimals);

        targetPool.fundRestorerList[msg.sender] += amountWithDecimals;
        targetPool.totalList[DataType.FUNDS_RESTORED] += amountWithDecimals;

        emit RestoreFunds(msg.sender, poolID, tokenAmount);
    }

    function collectInterestPoolFunds(uint256 tokenAmount) external
    nonReentrant
    onlyAdmins
    enoughFundsInInterestPool(tokenAmount * tokenDecimals){
        uint256 amountWithDecimals = tokenAmount * tokenDecimals;

        interestCollectorList[msg.sender] += amountWithDecimals;
        interestPool -= amountWithDecimals;

        _sendToken(msg.sender, amountWithDecimals);
        emit CollectInterest(msg.sender, tokenAmount);
    }

    function provideInterest(uint256 tokenAmount) external
    nonReentrant
    onlyAdmins {
        uint256 amountWithDecimals = tokenAmount * tokenDecimals;
        _receiveToken(amountWithDecimals);

        interestProviderList[msg.sender] += amountWithDecimals;
        interestPool += amountWithDecimals;

        emit ProvideInterest(msg.sender, tokenAmount);
    }
}