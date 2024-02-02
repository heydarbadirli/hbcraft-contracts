// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {ERC20Staking} from "../src/ERC20Staking.sol";

contract MyStakingProgram is Script {
    address private _programTokenContractAddress = 0xf0949Dd87D2531D665010d6274F06a357669457a;
    uint256 private _stakingTarget = 10000000;
    uint256 private _defaultMinimumDeposit = 1;

    function run() external {
        vm.startBroadcast();

        ERC20Staking myStakingProgram = new ERC20Staking(_programTokenContractAddress, _stakingTarget, _defaultMinimumDeposit);
        console.log("Contract deployed at:", address(myStakingProgram));

        vm.stopBroadcast();
    }
}
