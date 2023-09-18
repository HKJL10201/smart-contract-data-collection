pragma solidity ^0.4.23;
//Specifying what version of compiler this code will compile with

contract Voting {
  /* mapping field below is equivalent to an associative array or hash.
  */
  
  mapping (bytes32 => uint8) public votesReceived;
  
  
  
  bytes32[] public candidateList;

  /* This is the constructor which will be called once when the
 the contract is deployed on the blockchain. When the contract is deployed,
 it will take an array of candidates for which users will give their vote
  */
  
  constructor(bytes32[] memory candidateNames) public {
       candidateList = candidateNames;
  }
  

  // This function returns the total votes a a candidate has received so far
  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    return votesReceived[candidate];
  }

  // This function increments the vote count for the specified candidate. Casting a vote
  function voteForCandidate(bytes32 candidate) public {
    votesReceived[candidate] += 1;
  }
}
