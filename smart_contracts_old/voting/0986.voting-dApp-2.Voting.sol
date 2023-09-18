pragma solidity ^0.4.18;

contract Voting {
  
    // setting up mapping (equivalent to associative array or hash)
    mapping (bytes32 => uint8) public votesReceived;

    // use bytes32 instead of string since solidity currently doesn't allow an array of strings
    bytes32[] public candidateList;

    // constructor to be called when deploying to the blockchain
    // when we deploy the contract, an array of Candidate names with be passed
    function Voting(bytes32[] candidateNames) public {
        candidateList = candidateNames;
    }

    // returns current total votes for specific candidate
    function totalVotesFor(bytes32 candidate) view public returns (uint8) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    // increment total votes when valid vote is made
    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate));
        votesReceived[candidate] += 1;
    }

    // performs check to ensure candidate has been set up in the list and is valid
    function validCandidate(bytes32 candidate) view public returns (bool) {
        for(uint i = 0; i < candidateList. length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }

}