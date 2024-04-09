// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.22;

import "./store-functions/AdministrativeFunctions.sol";
import "./store-functions/PurchaseFunctions.sol";

/// @title ERC1155 Store by HB Craft (v1.0.0)
/// @author Heydar Badirli
contract ERC1155Store is AdministrativeFunctions, PurchaseFunctions {
    constructor(address dexPoolAddress) StoreManager(dexPoolAddress) WriteFunctions() {}
}
