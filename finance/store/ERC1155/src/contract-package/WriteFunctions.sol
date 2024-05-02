// SPDX-License-Identifier: GPL-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./ReadFunctions.sol";

abstract contract WriteFunctions is ReadFunctions {
    function _updateStateVariables(RatePeriod period) internal {
        if (period == RatePeriod.LOCK) {
            lastCheckedBTQTRate = getCurrentBTQTRate();
        } else if (period == RatePeriod.NEW_LOCK) {
            lockedBTQTRate = lastCheckedBTQTRate;
            lastCheckedBTQTRate = getCurrentBTQTRate();
            lastBTQTRateLockTimestamp = lastBTQTRateLockTimestamp + rateLockDuration;
        } else {
            lockedBTQTRate = getCurrentBTQTRate();
            lastCheckedBTQTRate = getCurrentBTQTRate();
            lastBTQTRateLockTimestamp = block.timestamp;
        }
    }

    function _updateStateForCurrentPeriod() internal {
        RatePeriod period = checkRatePeriod();
        _updateStateVariables(period);
    }

    constructor() {
        contractOwner = msg.sender;
        treasury = msg.sender;
        _updateStateVariables(RatePeriod.FLOATING);
    }
}
