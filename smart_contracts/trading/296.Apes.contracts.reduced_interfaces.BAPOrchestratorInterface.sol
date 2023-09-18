// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterface {
    function mintingRefunded(uint256) external returns (bool);

    function claimedMeth(uint256) external view returns (uint256);

    function godsMintingDate(uint256) external view returns (uint256);

    function totalClaimed(uint256) external view returns (uint256);
}
