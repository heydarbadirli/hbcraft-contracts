/*
    Copyright 2024 HB Craft.
    Licensed under the Creative Commons Attribution 4.0 International License (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    https://creativecommons.org/licenses/by/4.0/
    Unless required by applicable law or agreed to in writing, creative works
    distributed under the License are distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: CC-BY-4.0
*/


pragma solidity ^0.8.0;


import "./contract-functions/AdministrativeFunctions.sol";
import "./contract-functions/StakingFunctions.sol";
import "./contract-functions/WithdrawFunctions.sol";


contract ERC20Staking is AdministrativeFunctions, StakingFunctions, WithdrawFunctions {
    constructor(){
        contractOwner = msg.sender;

        stakingToken = IERC20(0xf0949Dd87D2531D665010d6274F06a357669457a);
        stakingTarget = 10000000 ether;

        defaultMinimumDeposit = 100 ether;
    }
}
