// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Blockhash2 {

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function getBlock2() external view returns(uint) {
        return block.number;
    }

    function getBlockHash2() external view returns(bytes32) {
        return blockhash(block.number-1);
    }

    function getHashNumber2() external view returns(uint256) {
        return uint256(blockhash(block.number-1));
    }

    function getDivision2() external view returns(uint256) {
        uint256 coinFlip = uint256(blockhash(block.number-1)) / FACTOR;
        return coinFlip;
    }
}