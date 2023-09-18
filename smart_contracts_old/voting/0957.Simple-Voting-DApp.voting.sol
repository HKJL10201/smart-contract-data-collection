pragma solidity ^0.4.11;
// version of solidity

contract Voting {
  
  //map the name which stored as bytes32 to unsigned integer to store vote count
  mapping (bytes32 => uint8) public votesReceived;
  
  // Solidity doesnt allow array of string so use bytes32 instead
  
  bytes32[] public candidateList;

  // Contructor after deploying this contract
  function Voting(bytes32[] candidateNames) {
    candidateList = candidateNames;
  }

  // total votes received by a specific candidate
  function totalVotesFor(bytes32 candidate) returns (uint8) {
    if (validCandidate(candidate) == false) throw;
    return votesReceived[candidate];
  }

  // casting a vote to a specific candidate
  function voteForCandidate(bytes32 candidate) {
    if (validCandidate(candidate) == false) throw;
    votesReceived[candidate] += 1;
  }

  // Validation for candidate that exist in the candidate list
  function validCandidate(bytes32 candidate) returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}