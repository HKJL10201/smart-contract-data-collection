pragma solidity ^0.4.11;

contract Voting {
  mapping (bytes32 => uint8) public votesReceived;

  bytes32[] public candidateList;

  /*
    This is the constructor which will be called once when you
    deploy the contract to the blockchain. When we deploy the contract,
    we will pass an array of candidates who will be contesting in the election.
  */
  function Voting(bytes32[] candidateNames) {
    candidateList = candidateNames;
  }

  function validCandidate(bytes32 candidate) returns (bool) {
    for (uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }

    return false;
  }

  // This function returns the total votes a candidate has received so far.
  function totalVotesFor(bytes32 candidate) returns (uint8) {
    assert(validCandidate(candidate));

    return votesReceived[candidate];
  }

  // This function increments the vote count for the specified candidate.
  // This is equivalent to casting a vote
  function voteForCandidate(bytes32 candidate) {
    assert(validCandidate(candidate));

    votesReceived[candidate] += 1;
  }
}