// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract GifPronunciationPortal {
  uint256 softTotal;
  uint256 hardTotal;

  uint256 private seed;

  event NewVote(address indexed from, string name, string vote, uint256 timestamp);

  struct Vote {
    address voter;
    string name;
    string vote;
    uint256 timestamp;
  }

  Vote[] votes;

  mapping(address => uint256) public lastVoted;

  constructor() payable {
    console.log("This is a smart contract for voting on whether 'GIF' is pronounced with a hard or a soft G\n");

    seed = (block.timestamp + block.difficulty) % 100;
  }

  function castVote(string memory _name, bool isSoft) public {
    require(lastVoted[msg.sender] + 7 seconds < block.timestamp, "* * * * * * * YOU CAN ONLY VOTE ONCE EVERY 7 SECONDS * * * * * * *");
    lastVoted[msg.sender] = block.timestamp;

    seed = (block.difficulty + block.timestamp + seed) % 100;
    if (seed <= 1) {
      console.log("%s won!", msg.sender);

      uint256 prizeAmount = 0.00000001 ether;
      require(
        prizeAmount <= address(this).balance,
        "Trying to withdraw more money than is available in the contract."
      );

      (bool success, ) = (msg.sender).call{value: prizeAmount}("");
      require(success, "Failed to withdraw money from contract.");
    }

    if (isSoft) {
      softTotal +=1;
      console.log("%s thinks GIF is pronounced with a soft G (as in giraffe)\n", _name);
      votes.push(Vote(msg.sender, _name, "soft", block.timestamp));
      emit NewVote(msg.sender, _name, "soft", block.timestamp);
    } else {
      hardTotal +=1;
      console.log("%s thinks GIF is pronounced with a hard G (as in gorilla)\n", _name);
      votes.push(Vote(msg.sender, _name, "hard", block.timestamp));
      emit NewVote(msg.sender, _name, "hard", block.timestamp);
    }
  }

  function getAllVotes() public view returns (Vote[] memory) {
    return votes;
  }

  function getSoftTotal() public view returns (uint256) {
    console.log("we have %d total soft G votes\n", softTotal);

    return softTotal;
  }

  function getHardTotal() public view returns (uint256) {
    console.log("we have %d total hard G votes\n", hardTotal);

    return hardTotal;
  }
}