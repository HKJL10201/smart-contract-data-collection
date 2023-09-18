pragma solidity ^0.4.17;
// We have to specify what version of compiler this code will compile with

contract Voting {
  /* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is decision name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */
  
  mapping (bytes32 => uint8) public votesReceived;
  
  /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of decisions
  */
  
  bytes32[] public decisionList;

  /* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of decisions
  */
  function Voting(bytes32[] decisionNames) public {
    decisionList = decisionNames;
  }

  // This function returns the total votes a option has received so far
  function totalVotesFor(bytes32 decision) public returns (uint8) {
    require (validDecision(decision) == false);
    return votesReceived[decision];
  }

  // This function increments the vote count for the specified decision. 
  // This is equivalent to casting a vote
  function voteForDecision(bytes32 decision) public {
    require (validDecision(decision) == false); 
    votesReceived[decision] += 1;
  }

  function validDecision(bytes32 decision) public returns (bool) {
    for (uint i = 0; i < decisionList.length; i++) {
      if (decisionList[i] == decision) {
        return true;
      }
    }
    return false;
  }
}