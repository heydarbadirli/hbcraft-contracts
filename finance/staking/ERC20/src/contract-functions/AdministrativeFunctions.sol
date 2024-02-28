// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "../ComplianceCheck.sol";

abstract contract AdministrativeFunctions is ComplianceCheck {
    // ======================================
    // =     Program Parameter Setters      =
    // ======================================
    function transferOwnership(address userAddress) external onlyContractOwner {
        require(userAddress != address(0), "new contract owner cannot be zero");
        require(userAddress != msg.sender, "Same with current owner");
        contractOwner = userAddress;

        emit TransferOwnership(msg.sender, userAddress);
    }

    function addContractAdmin(address userAddress) external onlyContractOwner {
        require(userAddress != msg.sender, "Owner can not be an admin");
        contractAdmins[userAddress] = true;

        emit AddContractAdmin(userAddress);
    }

    function removeContractAdmin(address userAddress) external onlyContractOwner {
        contractAdmins[userAddress] = false;

        emit RemoveContractAdmin(userAddress);
    }

    function setDefaultStakingTarget(uint256 newStakingTarget) external onlyContractOwner {
        defaultStakingTarget = newStakingTarget;

        emit UpdateDefaultStakingTarget(newStakingTarget);
    }

    function setDefaultMinimumDeposit(uint256 newDefaultMinimumDeposit) external onlyContractOwner {
        if (newDefaultMinimumDeposit == 0) revert InvalidArgumentValue("Minimum Deposit", 1);
        defaultMinimumDeposit = newDefaultMinimumDeposit;

        emit UpdateDefaultMinimumDeposit(newDefaultMinimumDeposit);
    }

    /// @notice Adds a new, empty StakingPool instance to the stakingPoolList
    function _addStakingPool(
        PoolType typeToSet,
        uint256 stakingTargetToSet,
        uint256 minimumDepositToSet,
        bool stakingAvailabilityStatus,
        uint256 APYToSet
    ) private {
        StakingPool storage targetPool = stakingPoolList.push();
        targetPool.poolType = typeToSet;
        targetPool.stakingTarget = stakingTargetToSet;
        targetPool.minimumDeposit = minimumDepositToSet;
        targetPool.isStakingOpen = stakingAvailabilityStatus;
        targetPool.isWithdrawalOpen = (typeToSet == PoolType.LOCKED) ? false : true;
        targetPool.isInterestClaimOpen = true;
        targetPool.APY = APYToSet;

        emit AddStakingPool(
            stakingPoolList.length - 1,
            typeToSet,
            stakingTargetToSet,
            APYToSet / FIXED_POINT_PRECISION,
            minimumDepositToSet
        );
    }

    /// @dev Adds a pool with custom set properties
    function addStakingPoolCustom(
        PoolType typeToSet,
        uint256 stakingTargetToSet,
        uint256 minimumDepositToSet,
        bool stakingAvailabilityStatus,
        uint256 APYToSet
    ) external onlyContractOwner {
        if (minimumDepositToSet == 0) revert InvalidArgumentValue("Minimum Deposit", 1);
        if (APYToSet == 0) revert InvalidArgumentValue("APY", 1);
        _addStakingPool(
            typeToSet,
            stakingTargetToSet,
            minimumDepositToSet,
            stakingAvailabilityStatus,
            APYToSet * FIXED_POINT_PRECISION
        );
    }

    /**
     * @notice
     *     - Adds a new empty StakingPool instances
     *     - Sets its stakingTarget to defaultStakingTarget
     *     - Sets its minimumDeposit to defaultMinimumDeposit
     *     - Sets isStakingOpen true
     *     - Sets isWithdrawalOpen false
     *     - Sets isInterestClaimOpen true
     *
     */
    function addStakingPoolDefault(PoolType typeToSet, uint256 APYToSet) external onlyContractOwner {
        if (APYToSet == 0) revert InvalidArgumentValue("APY", 1);
        _addStakingPool(typeToSet, defaultStakingTarget, defaultMinimumDeposit, true, APYToSet * FIXED_POINT_PRECISION);
    }

    /**
     * @dev
     *     - Changes availabilty properties of all the staking pools to the predefined property settings except the ones ended
     *     - The function is used in resumeProgram
     *
     */
    function _resetProgramSettings() private {
        for (uint256 poolNumber = 0; poolNumber < stakingPoolList.length; poolNumber++) {
            if (!_checkIfPoolEnded(poolNumber, true)) {
                changePoolAvailabilityStatus(poolNumber, 0, true);
                changePoolAvailabilityStatus(poolNumber, 2, true);
                if (stakingPoolList[poolNumber].poolType == PoolType.LOCKED) {
                    changePoolAvailabilityStatus(poolNumber, 1, false);
                } else {
                    changePoolAvailabilityStatus(poolNumber, 1, true);
                }
            }
        }
    }

    // ======================================
    // =     Program Control Functions      =
    // ======================================
    /// @dev Functions to easily pause or resume the program

    /**
     * @notice
     *     - Sets isStakingOpen parameter of all the staking pools to false
     *     - Sets isWithdrawalOpen parameter of all the staking pools to false
     *     - Sets isInterestClaimOpen parameter of all the staking pools to false
     *
     */
    function pauseProgram() external onlyContractOwner {
        _changeAllPoolAvailabilityStatus(0, false);
        _changeAllPoolAvailabilityStatus(1, false);
        _changeAllPoolAvailabilityStatus(2, false);

        emit PauseProgram();
    }

    /**
     * @notice
     *     - Sets isStakingOpen parameter of all the staking pools to true
     *     - Sets isWithdrawalOpen parameter of all LOCKED staking pools to false
     *     - Sets isWithdrawalOpen parameter of all FLEXIBLE staking pools to true
     *     - Sets isInterestClaimOpen parameter of all the staking pools to true
     *
     */
    function resumeProgram() external onlyContractOwner {
        _resetProgramSettings();

        emit ResumeProgram();
    }

    // ======================================
    // =       Pool Parameter Setters       =
    // ======================================
    function setPoolStakingTarget(uint256 poolID, uint256 newStakingTarget)
        external
        onlyContractOwner
        ifPoolExists(poolID)
        ifPoolEnded(poolID)
    {
        stakingPoolList[poolID].stakingTarget = newStakingTarget;

        emit UpdateStakingTarget(poolID, newStakingTarget);
    }

    function changePoolAvailabilityStatus(uint256 poolID, uint256 parameterToChange, bool valueToAssign)
        public
        onlyContractOwner
        ifPoolExists(poolID)
        ifPoolEnded(poolID)
    {
        require(parameterToChange < 3, "Invalid Parameter");

        if (parameterToChange == 0) {
            stakingPoolList[poolID].isStakingOpen = valueToAssign;

            emit UpdateStakingStatus(msg.sender, poolID, valueToAssign);
        } else if (parameterToChange == 1) {
            stakingPoolList[poolID].isWithdrawalOpen = valueToAssign;

            emit UpdateWithdrawalStatus(msg.sender, poolID, valueToAssign);
        } else if (parameterToChange == 2) {
            stakingPoolList[poolID].isInterestClaimOpen = valueToAssign;

            emit UpdateInterestClaimStatus(msg.sender, poolID, valueToAssign);
        }
    }

    /// @dev Changes availabilty properties of all the staking pools except the ones ended
    function _changeAllPoolAvailabilityStatus(uint256 parameterToChange, bool valueToAssign) private {
        for (uint256 poolNumber = 0; poolNumber < stakingPoolList.length; poolNumber++) {
            if (!_checkIfPoolEnded(poolNumber, true)) {
                changePoolAvailabilityStatus(poolNumber, parameterToChange, valueToAssign);
            }
        }
    }

    function setPoolAPY(uint256 poolID, uint256 newAPY)
        public
        onlyContractOwner
        ifPoolExists(poolID)
        ifPoolEnded(poolID)
    {
        if (newAPY == 0) revert InvalidArgumentValue("APY", 1);

        uint256 APYValueToWei = newAPY * FIXED_POINT_PRECISION;
        require(APYValueToWei != stakingPoolList[poolID].APY, "The same as current APY");

        stakingPoolList[poolID].APY = APYValueToWei;
        emit UpdateAPY(poolID, newAPY);
    }

    function setPoolMiniumumDeposit(uint256 poolID, uint256 newMinimumDeposit)
        external
        onlyContractOwner
        ifPoolExists(poolID)
        ifPoolEnded(poolID)
    {
        if (newMinimumDeposit == 0) revert InvalidArgumentValue("Minimum Deposit", 1);
        stakingPoolList[poolID].minimumDeposit = newMinimumDeposit;

        emit UpdateMinimumDeposit(poolID, newMinimumDeposit);
    }

    /**
     * @notice
     *     - Sets endDate property of a StakingPool to the date and time the function called
     *     - Sets isStakingOpen property of the StakingPoll to false
     *     - Sets isWithDrawal property of the StakingPoll to true
     *     - Sets isInterestClaimOpen property of the StakingPoll to true
     *
     */
    function endStakingPool(uint256 poolID, uint256 _confirmationCode)
        external
        onlyContractOwner
        ifPoolExists(poolID)
        ifPoolEnded(poolID)
    {
        require(_confirmationCode == CONFIRMATION_CODE, "Incorrect Code");
        changePoolAvailabilityStatus(poolID, 0, false);
        changePoolAvailabilityStatus(poolID, 1, true);
        changePoolAvailabilityStatus(poolID, 2, true);
        stakingPoolList[poolID].endDate = block.timestamp;

        emit EndStakingPool(poolID);
    }

    // ======================================
    // =     FUND MANAGEMENT FUNCTIONS      =
    // ======================================
    /// @dev Collects staked funds from the target StakingPool
    function collectFunds(uint256 poolID, uint256 tokenAmount)
        external
        nonReentrant
        onlyContractOwner
        ifPoolExists(poolID)
        ifPoolEnded(poolID)
        enoughFundsAvailable(poolID, tokenAmount)
    {
        StakingPool storage targetPool = stakingPoolList[poolID];
        targetPool.totalList[DataType.FUNDS_COLLECTED] += tokenAmount;

        emit CollectFunds(msg.sender, poolID, tokenAmount);
        _sendToken(msg.sender, tokenAmount);
    }

    /// @dev Restores funds collected from the target StakingPool
    function restoreFunds(uint256 poolID, uint256 tokenAmount) external nonReentrant ifPoolExists(poolID) onlyAdmins {
        StakingPool storage targetPool = stakingPoolList[poolID];
        uint256 remainingFundsToRestore =
            targetPool.totalList[DataType.FUNDS_COLLECTED] - targetPool.totalList[DataType.FUNDS_RESTORED];

        if (tokenAmount > remainingFundsToRestore) {
            revert RestorationExceedsCollected(tokenAmount, remainingFundsToRestore);
        }

        targetPool.fundRestorerList[msg.sender] += tokenAmount;
        targetPool.totalList[DataType.FUNDS_RESTORED] += tokenAmount;

        emit RestoreFunds(msg.sender, poolID, tokenAmount);
        _receiveToken(tokenAmount);
    }

    function collectInterestPoolFunds(uint256 tokenAmount)
        external
        nonReentrant
        onlyContractOwner
        enoughFundsInInterestPool(tokenAmount)
    {
        interestPool -= tokenAmount;

        emit CollectInterest(msg.sender, tokenAmount);
        _sendToken(msg.sender, tokenAmount);
    }

    function provideInterest(uint256 tokenAmount) external nonReentrant onlyAdmins {
        interestProviderList[msg.sender] += tokenAmount;
        interestPool += tokenAmount;

        emit ProvideInterest(msg.sender, tokenAmount);
        _receiveToken(tokenAmount);
    }
}
