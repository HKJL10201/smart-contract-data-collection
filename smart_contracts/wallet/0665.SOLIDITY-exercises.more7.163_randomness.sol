//SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

contract Randomness {

    function getRandom() external view returns(uint) {
        return block.prevrandao;
    }

    /*
    pseudo-randomness: not a true random number
    safer than using: uint(keccak256(abi.encodePacked(msg.sender, randomNum, block.timestamp)))
    validator can affect it to very small extent
    */

}