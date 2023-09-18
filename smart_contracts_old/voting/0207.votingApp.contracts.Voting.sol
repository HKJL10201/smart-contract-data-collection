pragma solidity ^0.4.11;

contract Voting {
  mapping (bytes32 => uint8) public votesReceived; // hash array of candidate in key and number of voting in value

  bytes32[] public candidateList; // candidate list

  function Voting(bytes32[] candidateNames) { // constructor we fill the candateList
    candidateList = candidateNames;
  }

  function totalVotesFor(bytes32 candidate) returns (uint8) { // function return the number of vote of one candidate
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate) {
    if (validCandidate(candidate) == false) throw;
    votesReceived[candidate] += 1;
  }

  function validCandidate(bytes32 candidate) returns (bool) {
    for (uint i=0; i<candidateList.length; i++) {
      if (candidateList[i] == candidate) return true;
    }
    return false;
  }
}