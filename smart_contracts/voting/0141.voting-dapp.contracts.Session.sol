// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Session is Ownable{
  struct VoteSession {
    string name;
    uint blockNumber;
  }

  uint64 private sessionBlock;
  mapping(uint8 => VoteSession) private indexToSession;

  constructor() {
    sessionBlock = 10;
    
    // Inactive Session at index 0
    indexToSession[0].name = "Inactive";
    // Registration Session at index 1
    indexToSession[1].name = "Registration";
    // Voting Session at index 2;
    indexToSession[2].name = "Voting";
  }

  event SessionStarted(uint startBlock, uint endBlock);
  event SessionBlockUpdated(uint64 blockCount);

  modifier onlyInActive() {
    require(
      block.number > indexToSession[2].blockNumber, 
      "Vote session must be inactive"
    );
    _;
  }

  modifier onlyRegister() {
    require(
      block.number <= indexToSession[1].blockNumber, 
      "Only registration is allowed"
    );
    _;
  }

  modifier onlyVote() {
    require(
      block.number > indexToSession[1].blockNumber && 
        block.number <= indexToSession[2].blockNumber,
      "Only voting is allowed"
    );
    _;
  }

  function getCurrentSesson() external view returns (uint8, string memory, uint, uint) {
    uint _current = block.number;
    uint _inActive = indexToSession[0].blockNumber;
    uint _register = indexToSession[1].blockNumber;
    uint _voting = indexToSession[2].blockNumber;


    if(_current <= _register) {
      return (1, indexToSession[1].name, _current, _register);
    }

    else if(_current <= _voting) {
      return (2, indexToSession[2].name, _current, _voting);
    }

    else {
      return (0, indexToSession[0].name, _current, _inActive);
    }
  }

  function startSession() internal onlyInActive {
    indexToSession[1].blockNumber = block.number + sessionBlock;
    indexToSession[2].blockNumber = block.number + (2 * sessionBlock);
    indexToSession[0].blockNumber = block.number + (3 * sessionBlock);
    emit SessionStarted(block.number, indexToSession[3].blockNumber);
  }

  function updateSessionBlock(uint64 _blockCount) external onlyOwner {
    require(_blockCount > 0, "New block count must be greater than 0");
    sessionBlock = _blockCount;
    emit SessionBlockUpdated(_blockCount);
  } 
}
