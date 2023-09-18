// Second version of Voting contract

pragma solidity ^0.4.11;

contract Voting {

  struct Votes {
    uint8 votes;
    bool isValid;
  }

  mapping (bytes32 => Votes) public votes;

  function Voting(bytes32[] _candidates) public {
    for (uint i = 0; i < _candidates.length; i++) {
      votes[_candidates[i]].votes = 0;
      votes[_candidates[i]].isValid = true;
    }
  }

  function totalVotesFor(bytes32 _candidate) view public returns (uint8) {
    return votes[_candidate].votes;
  }

  function voteForCandidate(bytes32 _candidate) public {
    require(validCandidate(_candidate) == true);
    votes[_candidate].votes += 1;
  }

  function validCandidate(bytes32 _candidate) view public returns (bool) {
    return votes[_candidate].isValid == true;
  }
}