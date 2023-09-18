// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IOracle {
    /**
     * return amount of tokens that are required to receive that much eth.
     */
    function getEthPrice() external view returns (uint256);
}
