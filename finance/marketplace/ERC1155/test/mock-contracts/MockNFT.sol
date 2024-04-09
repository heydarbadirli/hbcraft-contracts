// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockNFT is ERC1155 {
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant THORS_HAMMER = 2;
    uint256 public constant SWORD = 3;
    uint256 public constant SHIELD = 4;

    constructor(address lister) ERC1155("test") {
        _mint(lister, GOLD, 10, "");
        _mint(lister, SILVER, 20, "");
        _mint(lister, THORS_HAMMER, 30, "");
        _mint(lister, SWORD, 40, "");
        _mint(lister, SHIELD, 50, "");

        for (uint256 x = 5; x < 150; x++) {
            _mint(lister, x, 30, "");
        }
    }
}
