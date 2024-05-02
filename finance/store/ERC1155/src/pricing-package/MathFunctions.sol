// SPDX-License-Identifier: GPL-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

abstract contract MathFunctions {
    function _findDigitCount(uint256 number) internal pure returns (uint256) {
        uint256 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function _roundNumber(uint256 number, uint256 roundToDigits) internal pure returns (uint256) {
        uint256 digitCount = _findDigitCount(number);
        uint256 divisor = 10 ** (digitCount - roundToDigits);
        uint256 divided = number / divisor;
        uint256 remainder = number % divisor;

        // Round up
        if (remainder >= divisor / roundToDigits) return (divided + 1) * divisor;
        // Round down
        else return divided * divisor;
    }
}
