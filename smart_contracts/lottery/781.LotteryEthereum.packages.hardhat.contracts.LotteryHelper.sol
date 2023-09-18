pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract LotteryHelper {
  using SafeMath for uint256;

  /// @dev Generate 5 numbers ( 1 <= x >= 25) with no duplicate
  /// @param userProvidedSeed used for the random generator number function
  /// @return uint256[5] return an array of 5 generated uint
  function generateRandomTicketNumbers(uint256 userProvidedSeed) internal view returns (uint8[5] memory) {
    uint8[5] memory numbers;
    uint256 counter = 0;
    uint8[25] memory possibleNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25];

    // Shuffe the array of possible numbers (Fischer)
    for (uint256 i = 0; i < 5; i++) {
      uint256 j = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, i, counter, userProvidedSeed))) % 25;
      (possibleNumbers[i], possibleNumbers[j]) = (possibleNumbers[j], possibleNumbers[i]);
      counter++;
    }

    // Take first 5
    for (uint256 i = 0; i < numbers.length; i++) {
      numbers[i] = possibleNumbers[i];
    }

    return numbers;
  }

  function compareTwoUintArray(uint8[5] memory _drawNumbers, uint8[5] memory _ticketNumbers) internal pure returns (uint256) {
    uint256 commonNumbers = 0;

    for (uint256 i = 0; i < _drawNumbers.length; i++) {
      for (uint256 j = 0; j < _ticketNumbers.length; j++) {
        if (_drawNumbers[i] == _ticketNumbers[j]) {
          commonNumbers = commonNumbers.add(1);
        }
      }
    }
    return commonNumbers;
  }
}
