// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
  mapping (string => uint256) public votesReceived;
  string[] public candidateList;
   mapping (address => bool) public hasVoted;
  address public owner = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can call this function");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function initializeCandidates(string memory candidate) public onlyOwner {
    require(candidateList.length < 6, "Maximum number of candidates reached");
    candidateList.push(candidate);
  }

  function voteForCandidate(string memory candidate) public payable {
    require(validCandidate(candidate), "Invalid candidate");
    require(!hasVoted[msg.sender],"you have voted");
    votesReceived[candidate] += 1;
    hasVoted[msg.sender] = true;
  }

  function validCandidate(string memory candidate) public view returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (keccak256(bytes(candidateList[i])) == keccak256(bytes(candidate))) {
        return true;
      }
    }
    return false;
  }

  function totalVotesReceived() public view returns (uint256) {
    uint256 totalVotes = 0;
    for (uint i = 0; i < candidateList.length; i++) {
      totalVotes += votesReceived[candidateList[i]];
    }
    return totalVotes;
  }
  function getWinner() public view returns (string memory) {
  require(candidateList.length > 0, "No candidates found");

  uint256 maxVotes = votesReceived[candidateList[0]];
  string memory winner = candidateList[0];

  for (uint i = 1; i < candidateList.length; i++) {
    if (votesReceived[candidateList[i]] > maxVotes) {
      maxVotes = votesReceived[candidateList[i]];
      winner = candidateList[i];
    }
  }

  return winner;
}

}
