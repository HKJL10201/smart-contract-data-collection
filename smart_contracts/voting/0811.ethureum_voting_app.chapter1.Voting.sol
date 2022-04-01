// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Voting{
    //constructor to initialize candidates
    //vote for candidates
    //count a vote for each candidate
    bytes32[] public candidateList;
    mapping (bytes32 => uint8) public votesReceived;
    constructor(bytes32[] memory candidatesNames) {
        candidateList = candidatesNames;
    }

    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate)); 
        votesReceived[candidate] += 1;
    }

    function totalVotesFor(bytes32 candidate) view public returns(uint8){
        require(validCandidate(candidate)); 
        return votesReceived[candidate];
    }

    function validCandidate(bytes32 candidate) view public returns(bool){
        for(uint i = 0; i < candidateList.length; i++){
            if(candidateList[i]==candidate){
                return true;
            }
        }
        return false;
    }
}
