// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "./AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract ComplianceCheck is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // ======================================
    // =              Errors                =
    // ======================================
    // DEV: Exception raised when the stakeToken function called while the isStakingOpen parameter of the pool is false
    // DEV: Exception raised when the withdrawDeposit or withdrawAll function called while the isWithdrawalOpen parameter of the pool is false
    error NotOpen(uint256 poolID, string _action);
    // DEV: Exception raised if the pool data related functions called before any pools created
    error NoPoolsCreatedYet();
    // DEV: Exception raised if the function called to stake in a non-existent pool
    error PoolDoNotExist(uint256 poolID);
    // DEV: Exception raised if the total staked token amount will surrpass the stakingTarget with the intended token amount to stake
    error AmountExceedsTarget();
    // DEV: Exception raised if the token amount sent is over the fund left to restore
    error RestorationExceedsCollected(uint256 _tokenSent, uint256 _RemainingAmountToRestore);
    // DEV: Exception raised when the intended token amount to stake is lower than StakingPool.minimumDeposit
    error InsufficentDeposit(uint256 _tokenSent, uint256 _requiredAmount);
    // DEV: Exception raised when users try to withdraw from a staking pool which they haven't staked any tokens in
    error NoFundsStaked();
    // DEV: Exception raised when users try to withdraw from a staking pool which there is not enough token to withdraw from
    // DEV: Can happen after contract admins collecting funds and diminishing the funds of the target staking pool
    error NotEnoughFundsInThePool(uint256 poolID, uint256 requestedAmount, uint256 availableAmount);
    // DEV: Exception raised when the admins try to collect from the interestPool when there is not enough token to collect
    error NotEnoughFundsInTheInterestPool(uint256 requestedAmount, uint256 availableAmount);
    // DEV: Exception raised when the contract owner calls the program control functions after the program ended
    error StakingProgramEnded();


    // ======================================
    // =             Functions              =
    // ======================================
    function _checkAvailability(uint256 poolID, PoolDataType propertyToCheck) private view {
        StakingPool storage targetPool = stakingPoolList[poolID];
        string memory action;

        if (propertyToCheck == PoolDataType.IS_STAKING_OPEN && !targetPool.isStakingOpen) {
            action = "Staking";
        } else if (propertyToCheck == PoolDataType.IS_WITHDRAWAL_OPEN && !targetPool.isWithdrawalOpen) {
            action = "Withdrawal";
        } else if (propertyToCheck == PoolDataType.IS_INTEREST_CLAIM_OPEN && !targetPool.isInterestClaimOpen) {
            action = "Interest Claim";
        }

        if (bytes(action).length != 0){revert NotOpen(poolID, action);}
    }

    function _checkPoolExistence(uint256 poolID) private view {
        if (!(poolID < (stakingPoolList.length))) {revert PoolDoNotExist(poolID);}
    }

    function _checkProgramStatus() private view {
        uint256 length = stakingPoolList.length;
        if (length <= 0){revert NoPoolsCreatedYet();}
    }

    // ======================================
    // =             Modifiers              =
    // ======================================
    modifier ifProgramEnded () {
        if (programEndDate != 0){
            if  (block.timestamp > programEndDate){
                revert StakingProgramEnded();
            }
        }
        _;
    }

    modifier ifPoolExists (uint256 poolID) {
        _checkPoolExistence(poolID);
        _;
    }

    modifier ifProgramLaunched () {
        _checkProgramStatus();
        _;
    }

    // DEV: Checks if the necessary pool is open for staking, withdrawal or interest claim, raises exception if not
    modifier ifAvailable (uint256 poolID, PoolDataType propertyToCheck) {
        _checkAvailability(poolID, propertyToCheck);
        _;
    }
    
    // DEV: Checks if the total funds in the pools will exceed the target staking amount with the current staking request, raises exception if yes
    modifier ifTargetReached (uint256 _amountToStake, uint256 _totalStaked){
        if (_amountToStake > ((stakingTarget / tokenDecimals) - _totalStaked)){
            revert AmountExceedsTarget();
        }
        _;
    }

    // DEV: Checks if the deposit amount is higher the minimum required amount, raises exception if not
    modifier enoughTokenSent (uint256 tokenSent, uint256 _minimumDeposit) {
        if (tokenSent < _minimumDeposit){
            revert InsufficentDeposit({_tokenSent : tokenSent / tokenDecimals, _requiredAmount : _minimumDeposit / tokenDecimals});
        }
        _;
    }

    // DEV: Checks if the user have any funds to withdraw, raises exception if not
    modifier sufficientBalance (uint256 poolID) {
        if (stakingPoolList[poolID].stakerList[msg.sender] == 0){
            revert NoFundsStaked();
        }
        _;
    }

    // DEV: Checks if enough funds available in a pool, raises exception if not
    modifier enoughFundsAvailable (uint256 poolID, uint256 amountToCheck) {
        StakingPool storage targetStakingPool = stakingPoolList[poolID];
        uint256 fundAvailableToClaim = targetStakingPool.totalList[DataType.STAKED] - targetStakingPool.totalList[DataType.FUNDS_COLLECTED] + targetStakingPool.totalList[DataType.FUNDS_RESTORED];
        if (amountToCheck > fundAvailableToClaim){
                revert NotEnoughFundsInThePool(poolID, amountToCheck, fundAvailableToClaim);
        }
        _;
    }

    // DEV: Checks if enough funds available in a pool, raises exception if not
    modifier enoughFundsInInterestPool (uint256 amountToCheck) {
        if (amountToCheck > interestPool){
                revert NotEnoughFundsInTheInterestPool(amountToCheck, interestPool);
        }
        _;
    }


    // ======================================
    // =              Events                =
    // ======================================
    event Stake (address indexed user, uint256 indexed poolID, PoolType indexed poolType, uint256 depositNumber, uint256 tokenAmount);
    event Withdraw (address indexed user, uint256 indexed poolID, PoolType indexed poolType, uint256 depositNumber, uint256 tokenAmount);
    event CollectFunds (address indexed by, uint256 indexed poolID, uint256 tokenAmount);
    event RestoreFunds (address indexed by, uint256 indexed poolID, uint256 tokenAmount);
    event ProvideInterest (address indexed by, uint256 tokenAmount);
    event CollectInterest (address indexed by, uint256 tokenAmount);
    event APYUpdated (uint256 indexed poolID, uint256 APY);
    event ClaimInterest (address indexed user, uint256 indexed poolID, uint256 depositNumber, uint256 tokenAmount);

    
    // ======================================
    // =    Token Management Functions      =
    // ======================================
    function _receiveToken(uint256 tokenAmount) internal {
        stakingToken.safeTransferFrom(msg.sender, address(this), tokenAmount);
    }

    function _sendToken(address toAddress, uint256 tokenAmount) internal {
        stakingToken.safeTransfer(toAddress, tokenAmount);
    }
}