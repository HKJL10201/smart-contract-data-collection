// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';

contract Lottery is Ownable, VRFConsumerBase {
  address[] public participants;
  address[] public winners;
  mapping(address => bool) private isParticipating;
  mapping(address => bool) public isWinner;
  bool public randNumGenerated;
  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 internal randomResult;
  uint256 internal prevWinnerHash;

  /**
   * Constructor inherits VRFConsumerBase
   *
   * Network: Kovan
   * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
   * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
   * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
   */
  constructor()
    VRFConsumerBase(
      0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
      0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
    )
  {
    keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    fee = 0.1 ether; // 0.1 LINK (Varies by network)
  }

  /**
   * Requests randomness
   */
  function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
    require(
      randNumGenerated == false,
      'Random Number has already been generated'
    );
    require(
      LINK.balanceOf(address(this)) >= fee,
      'Not enough LINK - fill contract with faucet'
    );
    randNumGenerated = true;
    return requestRandomness(keyHash, fee);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    randomResult = randomness;
  }

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

  function selectWinners(uint256 _winnerCount) external onlyOwner {
    require(randomResult != 0, 'generate a random number first');

    uint256 randNumHash;
    uint256 randNum;
    uint256 cycles;
    uint256 nonce;

    if (prevWinnerHash == 0) {
      prevWinnerHash = randomResult;
    }

    do {
      randNumHash = uint256(keccak256(abi.encodePacked(prevWinnerHash, nonce)));
      randNum = randNumHash % participants.length;
      if (isWinner[participants[randNum]] == true) {
        nonce++;
        continue;
      }
      _pickWinner(randNum);
      prevWinnerHash = randNumHash;
      cycles++;
      nonce++;
    } while (cycles < _winnerCount);
  }

  function _pickWinner(uint256 _randomNum) internal {
    address selected = participants[_randomNum];
    isWinner[selected] = true;
    winners.push(selected);
  }

  function showWinners() external view returns (address[] memory) {
    return winners;
  }

  function showWinnersCount() external view returns (uint256) {
    return winners.length;
  }

  //@dev random function is replaced by VRF randomness

  // function _randomNum() internal view returns (uint256) {
  //   require(participants.length > 0, 'There are no participants');
  //   uint256 randomNumber = uint256(
  //     keccak256(
  //       abi.encodePacked(block.timestamp, block.difficulty, participants.length)
  //     )
  //   ) % participants.length;
  //   return randomNumber;
  // }
}
