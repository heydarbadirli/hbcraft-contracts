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

        emit AddContractAdmin(userAddress);
    }

    function removeContractAdmin(address userAddress) external
    onlyContractOwner {
        contractAdmins[userAddress] = false;

        emit RemoveContractAdmin(userAddress);
    }

    function setDefaultStakingTarget(uint256 newStakingTarget) external
    onlyContractOwner {
        defaultStakingTarget = newStakingTarget * tokenDecimals;

        emit UpdateDefaultStakingTarget(newStakingTarget);
    }

    function setDefaultMinimumDeposit(uint256 newDefaultMinimumDeposit) external
    onlyContractOwner {
        defaultMinimumDeposit = newDefaultMinimumDeposit * tokenDecimals;

        emit UpdateDefaultMinimumDeposit(newDefaultMinimumDeposit);
    }

    function _addStakingPool(PoolType typeToSet, uint256 stakingTargetToSet, uint256 minimumDepositToSet, bool stakingAvailabilityStatus, uint256 APYToSet) private {
        // NOTICE: Adds a new, empty StakingPool instance to the stakingPoolList
        stakingPoolList.push();

        // NOTICE: Accesses the newly created instance at the end of the array to set its properties
        uint256 newIndex = stakingPoolList.length - 1;
        StakingPool storage targetPool = stakingPoolList[newIndex];
        targetPool.poolType = typeToSet; // Set the poolType
        targetPool.stakingTarget = stakingTargetToSet; // Set the stakingTarget
        targetPool.minimumDeposit = minimumDepositToSet; // Set the minimumDeposit
        targetPool.isStakingOpen = stakingAvailabilityStatus; // Set the isStakingOpen
        targetPool.isWithdrawalOpen = (typeToSet == PoolType.LOCKED) ? false : true; // Set the isWithdrawalOpen
        targetPool.isInterestClaimOpen = true; // Set the isInterestClaimOpen
        targetPool.APY = APYToSet; // Set the APY

        emit AddStakingPool(newIndex, typeToSet, stakingTargetToSet / tokenDecimals, APYToSet / tokenDecimals, minimumDepositToSet / tokenDecimals);
    }

    function _convertUintToPoolType(uint256 typeAsUint) private pure
    returns (PoolType) {
        require(typeAsUint < 2, "Invalid Type");
        
        if (typeAsUint == 0) {
            return PoolType.LOCKED;
        } else {
            return PoolType.FLEXIBLE;
        }
    }

    // DEV: Adds a pool with custom set properties
    function addStakingPoolCustom(uint256 typeToSet, uint256 stakingTargetToSet, uint256 minimumDepositToSet, bool stakingAvailabilityStatus, uint256 APYToSet) external 
    onlyContractOwner {
        require(APYToSet != 0, "APY has to be over 0!");
        PoolType typeAsPoolType = _convertUintToPoolType(typeToSet);
        _addStakingPool(typeAsPoolType, stakingTargetToSet * tokenDecimals, minimumDepositToSet * tokenDecimals, stakingAvailabilityStatus, APYToSet * tokenDecimals);
    }

    // NOTICE: Adds a new empty StakingPool instances
    // NOTICE: Sets its stakingTarget to defaultStakingTarget
    // NOTICE: Sets its minimumDeposit to defaultMinimumDeposit
    // NOTICE: Sets isStakingOpen true
    // NOTICE: Sets isWithdrawalOpen false
    // NOTICE: Sets isInterestClaimOpen true
    function addStakingPoolDefault(uint256 typeToSet, uint256 APYToSet) external
    onlyContractOwner {
        require(APYToSet != 0, "APY has to be over 0!");
        PoolType typeAsPoolType = _convertUintToPoolType(typeToSet);
        _addStakingPool(typeAsPoolType, defaultStakingTarget, defaultMinimumDeposit, true, APYToSet * tokenDecimals);
    }

    // DEV: Changes availabilty properties of all the staking pools to the predefined property settings except the ones ended
    // DEV: The function is used in resumeProgram
    function _resetProgramSettings() private {
        for (uint256 poolNumber = 0; poolNumber < stakingPoolList.length; poolNumber++)
        {   
            if(_checkIfPoolEnded(poolNumber, true) == false){
                changePoolAvailabilityStatus(poolNumber, 0, true);
                changePoolAvailabilityStatus(poolNumber, 2, true);
                if (stakingPoolList[poolNumber].poolType == PoolType.LOCKED){
                    changePoolAvailabilityStatus(poolNumber, 1, false);
                }
                else {
                    changePoolAvailabilityStatus(poolNumber, 1, true);
                }
            }
        }
    }


    // ======================================
    // =     Program Control Functions      =
    // ======================================
    // DEV: Functions to easily launch, pause or resume the program

    // NOTICE: Sets isStakingOpen parameter of all the staking pools to false
    // NOTICE: Sets isWithdrawalOpen parameter of all the staking pools to false
    // NOTICE: Sets isInterestClaimOpen parameter of all the staking pools to false
    function pauseProgram() external
    onlyContractOwner {
        _changeAllPoolAvailabilityStatus(0, false);
        _changeAllPoolAvailabilityStatus(1, false);
        _changeAllPoolAvailabilityStatus(2, false);

        emit PauseProgram();
    }

    // NOTICE: Sets isStakingOpen parameter of all the staking pools to true
    // NOTICE: Sets isWithdrawalOpen parameter of all LOCKED staking pools to false
    // NOTICE: Sets isWithdrawalOpen parameter of all FLEXIBLE staking pools to true
    // NOTICE: Sets isInterestClaimOpen parameter of all the staking pools to true
    function resumeProgram() external
    onlyContractOwner {
        _resetProgramSettings();

        emit ResumeProgram();
    }


    // ======================================
    // =       Pool Parameter Setters       =
    // ======================================
    function setPoolStakingTarget(uint256 poolID, uint256 newStakingTarget) external
    onlyContractOwner
    ifPoolExists(poolID)
    ifPoolEnded(poolID) {
        stakingPoolList[poolID].stakingTarget = newStakingTarget * tokenDecimals;

        emit UpdateStakingTarget(poolID, newStakingTarget);
    }

    function changePoolAvailabilityStatus(uint256 poolID, uint256 parameterToChange, bool valueToAssign) public
    onlyAdmins
    ifPoolExists(poolID)
    ifPoolEnded(poolID) {
        require(parameterToChange < 3, "Invalid Parameter");

        if (parameterToChange == 0){
            stakingPoolList[poolID].isStakingOpen = valueToAssign;

            emit UpdateStakingStatus(msg.sender, poolID, valueToAssign);
        } else if (parameterToChange == 1){
            stakingPoolList[poolID].isWithdrawalOpen = valueToAssign;

            emit UpdateWithdrawalStatus(msg.sender, poolID, valueToAssign);
        } else if (parameterToChange == 2){
            stakingPoolList[poolID].isInterestClaimOpen = valueToAssign;

            emit UpdateInterestClaimStatus(msg.sender, poolID, valueToAssign);
        }
    }

    // DEV: Changes availabilty properties of all the staking pools except the ones ended
    function _changeAllPoolAvailabilityStatus(uint256 parameterToChange, bool valueToAssign) private {
        for (uint256 poolNumber = 0; poolNumber < stakingPoolList.length; poolNumber++)
        {
            if(_checkIfPoolEnded(poolNumber, true) == false){changePoolAvailabilityStatus(poolNumber, parameterToChange, valueToAssign);}
        }
    }

    function setPoolAPY (uint256 poolID, uint256 newAPY) public
    onlyContractOwner
    ifPoolExists(poolID)
    ifPoolEnded(poolID) {
        uint256 APYValueToWei = newAPY * tokenDecimals;
        require(newAPY != stakingPoolList[poolID].APY, "The same as current APY");

        stakingPoolList[poolID].APY = APYValueToWei;
        emit UpdateAPY(poolID, newAPY);
    }

    function setPoolMiniumumDeposit(uint256 poolID, uint256 newMinimumDeposit) external
    onlyAdmins
    ifPoolExists(poolID)
    ifPoolEnded(poolID) {
        stakingPoolList[poolID].minimumDeposit = newMinimumDeposit * tokenDecimals;

        emit UpdateMinimumDeposit(poolID, newMinimumDeposit);
    }

    // NOTICE: Sets endDate property of a StakingPoll to the date and time the function called
    // NOTICE: Sets isStakingOpen property of the StakingPoll to false
    // NOTICE: Sets isWithDrawal property of the StakingPoll to true
    // NOTICE: Sets isInterestClaimOpen property of the StakingPoll to true
    function endStakingPool(uint256 poolID, uint256 _confirmationCode) external
    onlyContractOwner
    ifPoolExists(poolID)
    ifPoolEnded(poolID) {
        require(_confirmationCode == confirmationCode, "Incorrect Code");
        changePoolAvailabilityStatus(poolID, 0, false);
        changePoolAvailabilityStatus(poolID, 1, true);
        changePoolAvailabilityStatus(poolID, 2, true);
        stakingPoolList[poolID].endDate = block.timestamp;

        emit EndStakingPool(poolID);
    }


    // ======================================
    // =     FUND MANAGEMENT FUNCTIONS      =
    // ======================================
    // DEV: Collects staked funds from the target StakingPool
    function collectFunds(uint256 poolID, uint256 tokenAmount) external
    nonReentrant
    onlyAdmins
    ifPoolExists(poolID)
    ifPoolEnded(poolID)
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
    ifPoolExists(poolID)
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