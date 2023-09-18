// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Voting{
    
    bytes32[] public candidateList;
    mapping (bytes32 =>uint8) public voteReceived;
    
    constructor(bytes32[] memory candidateNames) public{
        candidateList = candidateNames;
    }

    
    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate) == true);
        voteReceived[candidate]+=1;
    }
    
    function totalVotesFor(bytes32 candidate) public view returns(uint8){
        require(validCandidate(candidate) == true);
        return voteReceived[candidate];
    }
    
    function validCandidate(bytes32 candidate) view public returns(bool){
        for(uint i=0;i<candidateList.length; i++){
            if(candidateList[i] == candidate ){
                return true;
            }
        }
        return false;
    }
    
}