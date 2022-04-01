// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBribesManager {
    /// @param _proposal bytes32 of snapshot IPFS hash id for a given proposal
    function sendBribe(bytes32 _proposal) external;
}