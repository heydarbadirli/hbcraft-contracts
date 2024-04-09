// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {MockToken} from "./mock-contracts/MockToken.sol";
import {MockNFT} from "./mock-contracts/MockNFT.sol";
import {MockUniswap} from "./mock-contracts/MockUniswap.sol";

import {ERC1155Store} from "../src/ERC1155Store.sol";

contract TestSetUp is Test {
    MockToken baseToken;
    MockToken quoteToken;

    MockNFT testNFT;

    MockUniswap dexPool;

    ERC1155Store testStore;

    uint256 btDecimals = 6;
    uint256 qtDecimals = 18;

    uint256 buyerBalance = 1000000;

    address lister = address(50);
    address buyer = address(100);
    address buyer2 = address(200);
    address buyer3 = address(300);

    function setUp() external {
        baseToken = new MockToken(uint8(btDecimals));
        quoteToken = new MockToken(uint8(qtDecimals));
        dexPool = new MockUniswap(address(baseToken), address(quoteToken));

        baseToken.transfer(address(dexPool), 22000 * (10 ** btDecimals));
        quoteToken.transfer(address(dexPool), 320000 * (10 ** qtDecimals));
        quoteToken.transfer(buyer, buyerBalance * (10 ** qtDecimals));
        quoteToken.transfer(buyer2, buyerBalance * (10 ** qtDecimals));
        quoteToken.transfer(buyer3, buyerBalance * (10 ** qtDecimals));

        testStore = new ERC1155Store(address(dexPool));

        testNFT = new MockNFT(lister);
    }
}
