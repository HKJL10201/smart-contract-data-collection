// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RandomNumberGenerator {

    using SafeMath for uint256;

    /**
    * @dev Create random number
    * @notice This is not a secure way of generating a random number. Use Chainlink oracle for production.
    * @return pseudo random number between 1 - 1000
    */
    function _createRandomNumber() internal view returns (uint) {
        return (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 1000).add(1);
    }
}