// SPDX-License-Identifier: Apache License, Version 2.0
// Inspired by https://github.com/SetProtocol/set-protocol-strategies/blob/master/contracts/managers/triggers/ITrigger.sol

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

/// @title IBinaryIndicator
/// @notice Interface for interacting with Binary Indicator contracts
interface IBinaryIndicator {

    /// @notice Returns bool indicating if indicator is bullish 
    /// @return Boolean to represent if indicator is bullish
    function isBullish()
        external
        view
        returns (bool);
}