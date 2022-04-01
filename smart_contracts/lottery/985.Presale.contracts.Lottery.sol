// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract Lottery is Ownable {
  address[] public participants;
  address[] public winners;
  mapping(address => bool) private isParticipating;
  mapping(address => bool) public isWinner;

  function initParticipants(address[] memory _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      enterLottery(_addresses[i]);
    }
  }

  function enterLottery(address _address) public {
    require(
      isParticipating[_address] == false,
      'you are already in the lottery'
    );
    participants.push(_address);
    isParticipating[_address] = true;
  }

  function selectWinners(uint256 _winners) external onlyOwner {
    for (uint256 i = 0; i < _winners; i++) {
      _pickWinner();
    }
  }

  function _pickWinner() internal {
    uint256 randomNum = _randomNum();
    address selected = participants[randomNum];
    isWinner[selected] = true;
    winners.push(selected);
    participants[randomNum] = participants[participants.length - 1];
    participants.pop();
  }

  function _randomNum() internal view returns (uint256) {
    require(participants.length > 0, 'There are no participants');
    uint256 randomNumber = uint256(
      keccak256(
        abi.encodePacked(block.timestamp, block.difficulty, participants.length)
      )
    ) % participants.length;
    return randomNumber;
  }
}
