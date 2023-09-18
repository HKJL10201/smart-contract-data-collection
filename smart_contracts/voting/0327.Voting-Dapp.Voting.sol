pragma solidity ^0.4.11;
contract Voting {
  mapping(bytes32 => uint8) public votesReceived;
  bytes32[] public candidatesList;
  function Voting(bytes32[] candidatesNames) public {
    candidatesList = candidatesNames;
  }

  function voteFor(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function validCandidate(bytes32 candidate) view public returns (bool) {
    for (uint8 i = 0; i < candidatesList.length; i++) {
      if (candidatesList[i] == candidate) {
        return true;
      }
    }
    return false;
  }

}
