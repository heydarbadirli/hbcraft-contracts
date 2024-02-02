// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


library ArrayLibrary {
    function sum(uint[] memory array) internal pure
    returns (uint) {
        uint arrayValueSum = 0;
        for (uint i = 0; i < array.length; i++) {
            arrayValueSum += array[i];
        }
        return arrayValueSum;
    }
}