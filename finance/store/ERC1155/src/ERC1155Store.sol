// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./store-package/AdministrativeFunctions.sol";
import "./store-package/PurchaseFunctions.sol";

/// @title ERC1155 Store by HB Craft (v1.1.0)
/// @author Heydar Badirli
contract ERC1155Store is AdministrativeFunctions, PurchaseFunctions {
    constructor(address dexPoolAddress, uint256 _maximumAcceptableRate) StoreManager(dexPoolAddress, _maximumAcceptableRate) WriteFunctions() {}
}
