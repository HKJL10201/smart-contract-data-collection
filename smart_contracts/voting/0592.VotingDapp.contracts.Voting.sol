// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {

  struct Election {
    mapping(address => bool) eligibleVoters;
    mapping(address => uint) registeredVoters;
    mapping(bytes32 => uint) votes;
    bytes32[] candidates;
    bool open; // if true, anybody can register to vote
    string title;
  }

  Election[] public elections;
  mapping(address => uint[]) public postedElections;
  uint constant MAX_LENGTH = 15;

  function createElection(address[] memory voterPool, bytes32[] memory candidates, bool open, string memory title) public {
    elections.push(Election({candidates: candidates, open: open, title: title}));

    for(uint i = 0; i < voterPool.length; i++) {
      elections[elections.length - 1].eligibleVoters[voterPool[i]] = true;
    }
    postedElections[msg.sender].push(elections.length - 1);
  }

  function vote(uint i, bytes32 candidate) public {
    require(i >= 0, "Election not available");
    require(i < elections.length, "Election not available");
    require(!voted(i, msg.sender), "You have already voted");
    require(isEligibleToVote(i, msg.sender), "You are not eligible to vote");
    elections[i].registeredVoters[msg.sender] = 1;
    elections[i].votes[candidate]++;
  }

  function getElection(uint i) public view returns(bytes32[] memory, bool, string memory) {
    require(i >= 0, "Election not available");
    require(i < elections.length, "Election not available");
    return (elections[i].candidates, elections[i].open, elections[i].title);
  }

  function isEligibleToVote(uint i, address voter) public view returns (bool) {
    return elections[i].open || elections[i].eligibleVoters[voter];
  }

  function voted(uint i, address voter) public view returns (bool) {
    return elections[i].registeredVoters[voter] == 1;
  }

  function getNumberOfVotes(uint i, bytes32 candidate) public view returns (uint) {
    return elections[i].votes[candidate];
  }

  function getNumberOfElections() public view returns (uint) {
    return elections.length;
  }

  function getNumberOfElectionsCreatedByUser(address user) public view returns(uint) {
    return postedElections[user].length;
  }

}
