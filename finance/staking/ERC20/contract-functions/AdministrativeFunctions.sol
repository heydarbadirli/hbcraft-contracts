// SPDX-License-Identifier: CC-BY-4.0
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
        stakingTarget = newStakingTarget * 1 ether;
    }

    function setDefaultMinimumDeposit(uint256 newDefaultMinimumDeposit) external
    onlyContractOwner {
        defaultMinimumDeposit = newDefaultMinimumDeposit * 1 ether;
    }

    // NOTICE: For testing purposes
    /* function setProgramEndDate(uint256 dateInTimestamp) external
    onlyContractOwner {
        programEndDate = dateInTimestamp;
    } */

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
        _addStakingPool(typeToSet, minimumDepositToSet * 1 ether, stakingAvailabilityStatusToCheck, APYToSet * 1 ether);
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

        _addStakingPool(PoolType.LOCKED, defaultMinimumDeposit, true, lockedAndFlexibleAPY[0] * 1 ether);
        _addStakingPool(PoolType.FLEXIBLE, defaultMinimumDeposit, true, lockedAndFlexibleAPY[1] * 1 ether);
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
        programEndDate = uint128(block.timestamp);
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
        uint256 APYValueToWei = newAPY * 1 ether;
        require(newAPY != stakingPoolList[poolID].APY, "The same as current APY");

        stakingPoolList[poolID].APY = APYValueToWei;
        emit APYUpdated(poolID, newAPY);
    }

    function setPoolMiniumumDeposit(uint256 poolID, uint256 newMinimumDepositAmount) external
    onlyAdmins {
        stakingPoolList[poolID].minimumDeposit = newMinimumDepositAmount * 1 ether;
    }


    // ======================================
    // =     FUND MANAGEMENT FUNCTIONS      =
    // ======================================
    // DEV: Collects staked funds from the target StakingPool
    function collectFunds(uint256 poolID, uint256 etherAmount) external
    nonReentrant
    onlyAdmins
    enoughFundsAvailable(poolID, etherAmount * 1 ether) {
        uint256 etherToWeiAmount = etherAmount * 1 ether;
        StakingPool storage targetPool = stakingPoolList[poolID];
        targetPool.fundCollectorList[msg.sender] += etherToWeiAmount;
        targetPool.totalList[DataType.FUNDS_COLLECTED] += etherToWeiAmount;

        _sendToken(msg.sender, etherToWeiAmount);
        emit CollectFunds(msg.sender, poolID, etherAmount);
    }

    // DEV: Restores funds collected from the target StakingPool
    function restoreFunds(uint256 poolID, uint256 etherAmount) external
    nonReentrant
    onlyAdmins {
        StakingPool storage targetPool = stakingPoolList[poolID];
        uint256 remainingFundsToRestore = targetPool.totalList[DataType.FUNDS_COLLECTED] - targetPool.totalList[DataType.FUNDS_RESTORED];

        uint256 etherToWeiAmount = etherAmount * 1 ether;

        if (etherToWeiAmount > remainingFundsToRestore){
            revert RestorationExceedsCollected(etherAmount, remainingFundsToRestore);
        }

        _receiveToken(etherToWeiAmount);

        targetPool.fundRestorerList[msg.sender] += etherToWeiAmount;
        targetPool.totalList[DataType.FUNDS_RESTORED] += etherToWeiAmount;

        emit RestoreFunds(msg.sender, poolID, etherAmount);
    }

    function collectInterestPoolFunds(uint256 etherAmount) external
    nonReentrant
    onlyAdmins
    enoughFundsInInterestPool(etherAmount * 1 ether){
        uint256 etherToWeiAmount = etherAmount * 1 ether;

        interestCollectorList[msg.sender] += etherToWeiAmount;
        interestPool -= etherToWeiAmount;

        _sendToken(msg.sender, etherToWeiAmount);
        emit CollectInterest(msg.sender, etherAmount);
    }

    function provideInterest(uint256 etherAmount) external
    nonReentrant
    onlyAdmins {
        uint256 etherToWeiAmount = etherAmount * 1 ether;
        _receiveToken(etherToWeiAmount);

        interestProviderList[msg.sender] += etherToWeiAmount;
        interestPool += etherToWeiAmount;

        emit ProvideInterest(msg.sender, etherAmount);
    }
}