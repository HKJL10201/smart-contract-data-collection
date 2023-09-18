// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
interface ILottery {
    struct Player {
        string playerID;
        address playerAddr;
    }
}