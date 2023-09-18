pragma solidity ^0.4.20;


contract Voting {
 
  
  mapping (bytes32 => uint8) public votesReceived;
  bytes32[] public candidateList;
  
  function Voting(bytes32[] candidateNames) public{
    candidateList = candidateNames;
  }



  
  function totalVotesFor(bytes32 candidate)public returns (uint8) {
    if (validCandidate(candidate) == false) revert();
    return votesReceived[candidate];
  }

  
  function voteForCandidate(bytes32 candidate) {
    if (validCandidate(candidate) == false) revert();
    votesReceived[candidate] += 1;
  }

  function validCandidate(bytes32 candidate) returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}
