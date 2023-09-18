pragma solidity 0.5.16;

contract Voting {

  mapping (bytes32 => uint8) public receivedVotes; // mapping that links number of votes with the candidate
  mapping (bytes32 => bool) public candidates; // mapping to know if a candidate is valid

  constructor (bytes32[] memory _candidatesName) public {
    for(uint i = 0; i < _candidatesName.length; ++i) {
      candidates[_candidatesName[i]] = true;
    }
  }

  // Total number of votes received by a candidate
  function totalVotes (bytes32 candidate) public view returns (uint8) {
    require(candidateIsValid(candidate));
    return receivedVotes[candidate];
  }

  // Add one to the number of votes of a candidate
  function vote (bytes32 candidate) public {
    require(candidateIsValid(candidate));
    ++receivedVotes[candidate];
  }

  // Check that a candidate exists
  function candidateIsValid (bytes32 candidate) public view returns (bool) {
    return (candidates[candidate]);
  }
}