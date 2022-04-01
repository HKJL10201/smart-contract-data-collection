pragma solidity ^0.4.17;

contract Voting {
    //the key of this mapping is the candidate name stored as bytes32 type
    //
    mapping (bytes32=> uint8) public votesReceived;

    //this stores an arry of candidates bytes32
    bytes32[] public candidateList;

    /*this contructor will be called once when the contract is 
    deployed to the blockchain. It will pass an array of candidates
    contesting in the election once deployed*/
    function Voting(bytes32[] candidateNames) public {
        candidateList = candidateNames;
    }

    //this function returns totalvotes that a candidate has received so far.
    function totalVotesFor(bytes32 candidate) view public returns (uint8) {
        require(validateCandidate(candidate));
        return votesReceived[candidate];
    }
    //this function increments the vote count for each candidate, more like
    //the main votes function
    function voteForCandidate(bytes32 candidate) public returns (uint8) {
        require(validateCandidate(candidate));
        return votesReceived[candidate] += 1;
    }
    //function to validate the authenticity of the candidate
    function validateCandidate(bytes32 candidate) view public returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}