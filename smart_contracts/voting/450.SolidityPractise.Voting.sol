//Compiler version load
pragma solidity ^0.4.18;

contract Voting {

  //votes array
  mapping (bytes32 => uint8) public votesReceived;
  bytes32[] public candidateList;

  //Constructor
  function Voting(bytes32[] candidateNames) public {
    candidateList = candidateNames;
  }

  //Add candidate
  function addCandidate(bytes32 candidateName) public returns (string) {
    candidateList.push(candidateName);
    return 'candidate added';
  }

  //Return total votes for candidate
  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
   require(validCandidate(candidate));
   return votesReceived[candidate];
 }

  //Vote for Candidate
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  //Check valid candidate
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}
