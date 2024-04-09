// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    uint8 _tokenDecimals;

    constructor(uint8 tokenDecimals) ERC20("MockToken", "MKT") {
        _tokenDecimals = tokenDecimals;
        _mint(msg.sender, 1000000000 * (10 ** uint256(tokenDecimals))); // Mint 1 million tokens for the deployer
    }

    function decimals() public view virtual override returns (uint8) {
        return _tokenDecimals;
    }
}
