// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {MockNFT} from "./MockNFT.sol";
import {ERC1155Store} from "../src/ERC1155Store.sol";

contract TestSetUp is Test {
    IERC20 quoteToken;
    MockNFT testNFT;
    IUniswapV3Pool dexPool;
    ERC1155Store testStore;

    address dexPoolAddress = 0xf1be8652c37cA822F99363C8e18ff1D4E8F45D82;
    address qtAddress = 0xf0949Dd87D2531D665010d6274F06a357669457a;
    address whaleAddress = 0x176F3DAb24a159341c0509bB36B833E7fdd0a132;

    uint256 qtDecimals = 18;
    uint256 btDecimals = 6;
    uint256 buyerBalance = 100000;

    address lister = address(50);
    address buyer = address(100);
    address buyer2 = address(200);
    address buyer3 = address(300);
    address treasury = address(1500);

    function setUp() external {
        dexPool = IUniswapV3Pool(dexPoolAddress);
        quoteToken = IERC20(qtAddress);

        vm.startPrank(whaleAddress);
        quoteToken.transfer(buyer, buyerBalance * (10 ** qtDecimals));
        quoteToken.transfer(buyer2, buyerBalance * (10 ** qtDecimals));
        quoteToken.transfer(buyer3, buyerBalance * (10 ** qtDecimals));
        vm.stopPrank();

        testStore = new ERC1155Store(dexPoolAddress);
        testStore.changeTreasuryAddress(treasury);

        testNFT = new MockNFT(lister);
    }
}
