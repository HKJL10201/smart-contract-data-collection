// First version of Voting contract

pragma solidity ^0.4.11;

contract Voting {

  mapping (bytes32 => uint8) public votesReceived;
  bytes32[] public candidateList;

  function Voting(bytes32[] _candidates) public {
    candidateList = _candidates;
  }

  function totalVotesFor(bytes32 _candidate) view public returns (uint8) {
    return votesReceived[_candidate];
  }

  function voteForCandidate(bytes32 _candidate) public {
    if (validCandidate(_candidate) == false) {
      revert();
    }
    votesReceived[_candidate] += 1;
  }

  function validCandidate(bytes32 _candidate) view public returns (bool) {
    for (uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == _candidate) {
        return true;
      }
    }
    return false;
  }
}