// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/**
 * @title Ilottery Interface
 */

interface ILottery {
    /**
     * @dev External function for playing. This function can be called by only RandomNumberGenerator.
     * @param _randomness Arrayof Random Numbers
     */
    function declareWinner(uint256[] memory _randomness) external;
}