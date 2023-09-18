// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    /**
     * return amount of tokens that are required to receive that much eth.
     */
    function getTokenValueOfEth(
        uint256 ethOutput
    ) external view returns (uint256 tokenInput);
}
