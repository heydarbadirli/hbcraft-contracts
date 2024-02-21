// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ProgramManager {
    // ======================================
    // =          State Variables           =
    // ======================================
    IERC20Metadata public stakingToken;
    uint256 public stakingTokenDecimalCount;
    uint256 internal stakingTokenDecimals;

    /// @notice Default value to set the stakingTarget property for the new StakingPool if not specified
    uint256 internal defaultStakingTarget;
    /// @notice Default value to set the minimumDeposit property for the new StakingPool if not specified
    uint256 internal defaultMinimumDeposit;

    /**
     * @dev
     *     - For preventing accidentally ending a stakingPool
     *     - Set when the contract is deployed
     *     - Asked when endPool() function is called
     *
     */
    uint256 internal confirmationCode;

    /// @notice Program token balance for paying interests
    uint256 internal interestPool;
    /// @notice The list of users who donated/provided tokens to the interestPool
    /// @dev Direct token transactions (via receive function) ends up in the interestPool
    mapping(address => uint256) internal interestProviderList;

    /// @notice Each user can make infinite amount of deposits
    /// @dev A user's data for each deposit is kept seperately in stakingPoolList[poolID].stakerDepositList[userAddress]
    struct TokenDeposit {
        uint256 stakingDate;
        uint256 withdrawalDate;
        uint256 amount;
        uint256 APY;
        uint256 claimedInterest;
    }

    /**
     * @notice
     *     - The contract has ability to create 2 types of staking pools: LOCKED, FLEXIBLE
     *     - LOCKED staking pools' isWithdrawalOpen parameter is false by default
     *     - FLEXIBLE staking pools' isWithdrawalOpen parameter is true by default
     *
     */
    enum PoolType {
        LOCKED,
        FLEXIBLE
    }

    /// @dev DataType and PoolDataType are used for cleaner communication among the contract functions
    enum DataType {
        STAKED,
        WITHDREW,
        INTEREST_CLAIMED,
        FUNDS_COLLECTED,
        FUNDS_RESTORED
    }
    enum PoolDataType {
        IS_STAKING_OPEN,
        IS_WITHDRAWAL_OPEN,
        IS_INTEREST_CLAIM_OPEN
    }

    enum ActionType {
        STAKING,
        WITHDRAWAL,
        INTEREST_CLAIM
    }

    /**
     * @notice
     *     - Contract owners create as many pools as they want for different purposes
     *     - StakingPool's totalList[DataType.STAKED] parameter value can not be higher than stakingTarget
     *
     */
    /**
     * @dev
     *     - The endDate is set via endPool function when no more interest is intended to be paid after certain period of time
     *     - If the current time has passed the endDate, endDate is used when calculating the interests
     *
     */
    struct StakingPool {
        uint256 stakingTarget;
        uint256 minimumDeposit;
        uint256 APY;
        bool isStakingOpen;
        bool isWithdrawalOpen;
        bool isInterestClaimOpen;
        PoolType poolType;
        mapping(address => uint256) stakerList;
        address[] stakerAddressList;
        mapping(address => TokenDeposit[]) stakerDepositList;
        mapping(address => uint256) withdrawerList;
        mapping(address => uint256) interestClaimerList;
        mapping(address => uint256) fundRestorerList;
        mapping(DataType => uint256) totalList;
        uint256 endDate;
    }

    /// @dev The list holding all the created pools
    StakingPool[] internal stakingPoolList;
}
