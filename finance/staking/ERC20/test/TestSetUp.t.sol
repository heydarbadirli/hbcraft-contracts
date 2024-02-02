// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {MockToken} from "./MockToken.sol";

import {ERC20Staking} from "../src/ERC20Staking.sol";
import "../src/ProgramManager.sol";

contract TestSetUp is Test {
    MockToken myToken;

    uint256 myTokenDecimal = 18;
    uint256 myTokenDecimals = 10 ** myTokenDecimal;

    uint256 _stakingTarget = 10000;
    uint256 _defaultMinimumDeposit = 10;

    uint256 _lockedAPY = 200;
    uint256 _flexibleAPY = 10;

    ERC20Staking stakingContract;

    address contractAdmin = address(1);
    address userOne = address(2);

    address[] addressList = [contractAdmin, userOne];
    uint256 amountToProvide = 1000;
    uint256 amountToStake = 10;
 
    uint256 tokenToDistribute = 1000 * myTokenDecimals;
    uint256 tokenToStake = 10 * myTokenDecimals;

    enum PMActions {LAUNCH, PAUSE, RESUME, END}

    function setUp() external {
        myToken = new MockToken(myTokenDecimal);
        stakingContract = new ERC20Staking(address(myToken), _stakingTarget, _defaultMinimumDeposit);
        stakingContract.addContractAdmin(contractAdmin);

        for(uint256 userNo = 0; userNo < addressList.length; userNo++){
            myToken.transfer(addressList[userNo], tokenToDistribute);
        }
    }
}