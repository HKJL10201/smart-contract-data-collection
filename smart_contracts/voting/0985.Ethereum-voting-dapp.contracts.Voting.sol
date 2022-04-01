pragma solidity ^0.4.18;
// Specify version of compiler

contract Voting {
    // Mapping an associative array of 32bytes to an unsigned 8-bit integer
    // Candidate name will be stored in the 32Bytes
    // # of votes candidate has recieved stored as 8-bit integer
    mapping (bytes32=>uint8) public votesReceived;

    // an array of size 32 bytes
    bytes32[] public candidateList;

    // Constructor to be run when contract is deployed to blockchain
    // When we deploy the contract we need to pass in an array of candidates
    // That will participate in the election
    function Voting(bytes32[] candidateNames) public {
        candidateList = candidateNames;
    }
    
    // Gets the total number of votes received so far
    function totalVotesFor(bytes32 candidate) view public returns (uint) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    // Increments the vote count for a candidate by 1
    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate));
        votesReceived[candidate] += 1;
    }

    // Checks to see if presented candidate is valid
    function validCandidate(bytes32 candidate) view public returns (bool) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}