pragma solidity ^0.4.11;

contract Voting {
  mapping (bytes32 => uint8) public votes;
  bytes32[] public candidates;

  function Voting(bytes32[] names) {
    candidates = names;
  }

  function totalVotesForCandidate(bytes32 candidate) returns (uint8) {
    require(validCandidate(candidate));
    return votes[candidate];
  }

  function voteForCandidate(bytes32 candidate) {
    require(validCandidate(candidate));
    votes[candidate] += 1;
  }

  function validCandidate(bytes32 candidate) returns (bool) {
    for (uint i = 0; i < candidates.length; i++) {
      if (candidates[i] == candidate) {
        return true;
      }
    }

    return false;
  }
}
