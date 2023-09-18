// We have to specify what version of compiler this code will compile with
pragma solidity ^0.4.19;

contract SmartVoting {
  mapping (bytes32 => uint8) private votesReceived;
  mapping (address => bool) private voted;
  mapping (bytes32 => bool) private allowedCandidates;

  function SmartVoting(bytes32[] candidateNames) public {
    for(uint i = 0; i < candidateNames.length; i++) {
      allowedCandidates[candidateNames[i]] = true;
    }
  }

  function totalVotesFor(bytes32 candidate) public constant returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    if (voted[msg.sender] == false) {
      votesReceived[candidate] += 1;
      voted[msg.sender] = true;
    }
  }

  function validCandidate(bytes32 candidate) public constant returns (bool) {
    return allowedCandidates[candidate];
  }
}
