// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {
  mapping(uint256 => string) public candidates;
  mapping(uint256 => uint256) public votes;
  mapping(address => uint256) public hasVoted;

  event VoteMade(string _for, address _by);

  constructor() public {
    // set the 2 candidates - Michael Scott, Dwight Schrute
    candidates[1] = "Michael Scott";
    candidates[2] = "Dwight Schrute";
    votes[1] = 0;
    votes[2] = 0;
  }

  function vote(uint256 _candidateId) public {
    require(hasVoted[msg.sender] == 0);

    votes[_candidateId]++;
    hasVoted[msg.sender] = 1;

    emit VoteMade(candidates[_candidateId], msg.sender);
  }
}
