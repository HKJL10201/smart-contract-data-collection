pragma solidity ^0.4.11; // We have to specify the version of compiler

contract Voting {

  /**
   * A mapping property below is equivalent to an associative array or hash.
   * The key here is a candidate name stored as bytes32 type. Value is an
   * unsigned integer to store the vote count.
   */
  mapping (bytes32 => uint8) public votesReceived;
  
  /**
   * Solidity doesn't let you pass in an array of strings in the constructor (yet).
   * One of the options it to use bytes32 instead to store the list of candidates.
   */
  bytes32[] public candidateList;

  /**
   * This is the constructor which executes only once you deploy the contract.
   * When deploying this contract, we will pass an array of candidates of an election.
   */
  function Voting(bytes32[] candidateNames) {
    candidateList = candidateNames;
  }

  /**
   * This function returns the total number of votes particular candidate has received so far.
   */
  function totalVotesFor(bytes32 candidate) returns (uint8) {
    if (validCandidate(candidate) == false) throw;
    return votesReceived[candidate];
  }

  /**
   * This function increments the vote count for the specified candidate.
   */
  function voteForCandidate(bytes32 candidate) {
    if (validCandidate(candidate) == false) throw;
    votesReceived[candidate] += 1;
  }

  /**
   * This function checks whether a particular candidate participates in the election.
   */
  function validCandidate(bytes32 candidate) returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }

}