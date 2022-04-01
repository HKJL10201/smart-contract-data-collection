pragma solidity >=0.4.0 <0.6.0;
// This line says the code will compile with version greater than 0.4 and less than 0.6

contract Voting {
  // constructor to initialize candidates
  // vote for candidates
  // get count of votes for each candidates
  
  bytes32[] public candidateList;
  mapping (bytes32 => uint8) public votesReceived;

  constructor(bytes32[] memory candidateNames) public {
    // solidity requires that any 
    candidateList = candidateNames;
  }
  
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }
  
  function totalVotesFor(bytes32 candidate) view public returns(uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }
  
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i=0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
  
}
