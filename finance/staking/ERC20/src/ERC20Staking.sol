/*
Copyright 2024 HB Craft

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

SPDX-License-Identifier: Apache-2.0
*/


pragma solidity ^0.8.0;


import "./contract-functions/AdministrativeFunctions.sol";
import "./contract-functions/StakingFunctions.sol";
import "./contract-functions/WithdrawFunctions.sol";


contract ERC20Staking is AdministrativeFunctions, StakingFunctions, WithdrawFunctions {
    constructor(address tokenAddress, uint256 _defaultStakingTarget, uint256 _defaultMinimumDeposit, uint256 _confirmationCode){
        contractOwner = msg.sender;

        stakingToken = IERC20Metadata(tokenAddress);
        tokenDecimalCount = stakingToken.decimals();

        defaultStakingTarget = _defaultStakingTarget;
        defaultMinimumDeposit = _defaultMinimumDeposit;

        confirmationCode = _confirmationCode;

        emit CreateProgram(stakingToken.symbol(), tokenAddress, _defaultStakingTarget, _defaultMinimumDeposit); 
    }
}
