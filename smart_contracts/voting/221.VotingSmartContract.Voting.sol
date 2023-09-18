// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract Voting {
  
  // mapping for tracking vote count per candidate 
  // note that candiate names are kept via bytes32 (not string) to save gas
  mapping (bytes32 => uint256) public votesReceived;

  // tracking who has already voted 
  mapping (address => bool) internal voted;
  

// List of candidates stored in bytes32 to save gas  
  bytes32[] public candidateList;


// modifier to validate if candidate name is valid
  modifier validateCandidate(string memory candidate){
      require(validCandidate(candidate), "Invalid candidate name");
      _;
  }


  constructor(string[] memory candidateNames) {
      for(uint i = 0; i < candidateNames.length; i++){
          candidateList.push(keccak256(abi.encodePacked(candidateNames[i])));
      }
  }
  
  // This function returns the total votes a candidate has received so far
  function totalVotesFor(string memory candidate) view public validateCandidate(candidate) returns (uint256) {
    return votesReceived[keccak256(abi.encodePacked(candidate))];
  }

  // This function increments the vote count for the specified candidate. This
  // is equivalent to casting a vote
  function voteForCandidate(string memory candidate) public validateCandidate(candidate) {
      require(!voted[msg.sender], "You already voted");
      voted[msg.sender] = true;
      votesReceived[keccak256(abi.encodePacked(candidate))] += 1;
  }

  function validCandidate(string memory candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == keccak256(abi.encodePacked(candidate))) {
        return true;
      }
    }
    return false;
  }
}
