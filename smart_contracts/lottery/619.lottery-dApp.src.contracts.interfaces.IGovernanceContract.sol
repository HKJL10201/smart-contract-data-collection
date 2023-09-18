// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

interface IGovernanceContract {
    function lottery() external view returns (address);
    function randomness() external view returns (address);
}