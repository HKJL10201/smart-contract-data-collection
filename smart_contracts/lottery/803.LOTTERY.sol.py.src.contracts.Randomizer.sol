// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Randomizer {
    function getRandomValue(uint256 min, uint256 max)
        internal
        view
        returns (uint256)
    {
        return
            min +
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % (max - min + 1));
    }
}
