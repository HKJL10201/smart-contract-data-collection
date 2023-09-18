pragma solidity ^0.4.18;

contract Voting {
  //making candidates hash
  mapping (bytes32 => uint8) public votesReceived;
  bytes32[] public candidateList;

  //constructor
  function Voting(bytes32[] candidateNames) public {
    candidateList = candidateNames;
  }

  function totalVotesFor(bytes32 _candidate) view public validCandidate(_candidate) returns (uint8){
    //test out modifier instead of other function
    //require(validCandidate(_candidate));
    return votesReceived[_candidate]);
  }

  function voteForCandidate(bytes32 _candidate) public validCandidate(_candidate) {
    candidateList[_candidate] ++;
  }

  modifier validCandidate(bytes32 _candidate) public {
    for (uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == _candidate) {
        return true;
      }
    }
    return false;
  }

}
