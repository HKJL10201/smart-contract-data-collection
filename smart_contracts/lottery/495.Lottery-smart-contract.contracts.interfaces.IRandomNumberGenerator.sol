// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/**
 * @title RandomNumberGenerator Interface
 */
interface IRandomNumberGenerator {
    /**
     * @dev External function to request randomness and returns request Id. This function can be called by only apporved games.
     */
    function getRandomNumber() external returns (bytes32);
}