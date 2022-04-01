pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

contract Voting {
  /* mapping is equivalent to an associate array or hash
  The key of the mapping is candidate name stored as type uint8 and value is
  an unsigned integer which used to store the vote count
  */
  mapping (uint8 => uint8) public votesReceived;
  
  /* Solidity doesn't let you create an array of strings yet. We will use an array of uint8 instead to store
  the list of candidates
  */
  
  uint8[] public candidateList;

  // Initialize all the contestants
  function Voting(uint8[] candidateNames) public {
    candidateList = candidateNames;
  }

  function totalVotesFor(uint8 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(uint8 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  function validCandidate(uint8 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}

