pragma solidity ^0.4.23;

contract Voting{
    //Constructor to Initialize the candidates
    //Vote for canditates
    //get count of votes for each canditates

    bytes32[] public candidatesList;
    mapping (bytes32 => uint8) public votesReceived;
    constructor(bytes32[] candidateNames) public {
        candidatesList = candidateNames;
    }
    
    function voteForCandidate(bytes32 candidate) public{
        require(validCandidate(candidate));
        votesReceived[candidate] += 1;
    }
    
    function totalVotesFor(bytes32 candidate) view public returns(uint8){
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }
    
    function validCandidate(bytes32 candidate) view public returns(bool){
        for(uint i = 0; i < candidatesList.length; i++){
            if(candidatesList[i] == candidate){
                return true;
            }
        }
        return false;
    }
}