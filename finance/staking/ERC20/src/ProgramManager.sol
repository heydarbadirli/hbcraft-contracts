// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract ProgramManager {
    // ======================================
    // =          State Variables           =
    // ======================================
    IERC20Metadata public stakingToken;
    uint256 internal tokenDecimals;

    uint256 internal stakingTarget;
    // NOTICE: Default value to set the minimumDeposit parameter for the new StakingPool
    uint256 internal defaultMinimumDeposit;

    // NOTICE: Program token balance for paying interests
    uint256 internal interestPool;
    // NOTICE: The list of users who donated/provided tokens to the interestPool
    // DEV: Direct token transactions (via receive function) ends up in the interestPool
    mapping (address => uint256) internal interestProviderList;
    mapping (address => uint256) internal interestCollectorList;

    // NOTICE: The contract is designed for launching staking programs for undetermined period of time
    // DEV: The programEndDate is set via endProgram function when no more interest is intended to be paid
    // DEV: If the current time has passed the program end date, programEndDate is used when calculating the interests
    uint256 public programEndDate;

    // NOTICE: Each user can make infinite amount of deposits
    // DEV: A user's data for each deposit is kept seperately in stakingPoolList[poolID].stakerDepositList[userAddress]
    struct TokenDeposit {
        uint256 stakingDate;
        uint256 withdrawalDate;

        uint256 amount;

        uint256 APY;
        uint256 claimedInterest;
    }

    // NOTICE: The contract has ability to create 2 types of staking pools: LOCKED, FLEXIBLE
    // NOTICE: LOCKED staking pools' isWithdrawalOpen parameter is false by default
    // NOTICE: FLEXIBLE staking pools' isWithdrawalOpen parameter is true by default
    enum PoolType { LOCKED, FLEXIBLE }

    // DEV: DataType and PoolDataType are used for cleaner communication among the contract functions
    enum DataType {STAKED, WITHDREW, INTEREST_CLAIMED, FUNDS_COLLECTED, FUNDS_RESTORED, DEPOSIT_COUNT}
    enum PoolDataType {APY, IS_STAKING_OPEN, IS_WITHDRAWAL_OPEN, IS_INTEREST_CLAIM_OPEN}

    enum ActionType { STAKING, WITHDRAWAL, INTEREST_CLAIM }

    // NOTICE: Contract owners create as many pools as they want for different purposes
    // NOTICE: StakingPools' combined totalList[DataType.STAKED] parameter value can not be higher than stakingTarget
    struct StakingPool {
        PoolType poolType;
        uint256 minimumDeposit;

        bool isStakingOpen;
        bool isWithdrawalOpen;
        bool isInterestClaimOpen;

        uint256 APY;
    
        mapping (address => uint256) stakerList;
        mapping (address => TokenDeposit[]) stakerDepositList;

        mapping (address => uint256) withdrawerList;
        mapping (address => uint256) interestClaimerList;

        mapping (address => uint256) fundCollectorList;
        mapping (address => uint256) fundRestorerList;

        mapping (DataType => uint256) totalList;
    }

    // DEV: The list holding all the created pools
    StakingPool[] internal stakingPoolList;
}