// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAccountSetUp {
    function approveUnderlyings(address[] memory _underlyings) external;

    function enterMarkets(address[] memory cTokens) external;
}
