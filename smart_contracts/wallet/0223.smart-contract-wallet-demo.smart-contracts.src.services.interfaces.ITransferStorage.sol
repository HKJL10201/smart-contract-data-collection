// SPDX-License-Identifier: MIT only

pragma solidity ^0.8.0;

interface ITransferStorage {
    function addToWhitelist(address _wallet, address _target, uint256 _value) external;

    function isWhiteListed(address _wallet, address _target) external view returns (uint256);
}