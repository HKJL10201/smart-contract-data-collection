// compiler needs to be fixed
pragma solidity ^0.6.4;

contract Voting {
    //candidate names stored in bytes and mapped to the votes 
    mapping (bytes32 => uint256) public votesReceived;
    bytes32[] public candidateList;

    constructor(bytes32[] memory candidateNames) public {
    candidateList = candidateNames;
  }

  // function to return total number of votes a candiadte has received  
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // casting a vote using candiadte name
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  // validate candidate check 
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}