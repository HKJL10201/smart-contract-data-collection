pragma solidity ^0.4.11; // Version of compiler
contract Voting {
    /* mapping field => hashmap
    In this case, key is name
      Value is vote count
    */
    mapping (bytes32 => uint8) public votesReceived;
    /* Solidity doesn't allow array of strings in constructor.
        We use array of bytes32 instead */
    bytes32[] public candidateList;
    
    /* constructor called when contract is deployed */
    function Voting(bytes32[] candidateNames) {
        candidateList = candidateNames;
    }

    /* Function to return total votes received by candidate */
    function totalVotesFor(bytes32 candidate) returns (uint8) {
        if  (validCandidate(candidate) == false) throw;
        return votesReceived[candidate];
    }

    /* Function to vote for a candidate */
    function voteForCandidate(bytes32 candidate) {
        if(validCandidate(candidate) == false) throw;
        votesReceived[candidate] += 1;
    }

    /* Function to check if the candidate exists */
    function validCandidate(bytes32 candidate) returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if(candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}