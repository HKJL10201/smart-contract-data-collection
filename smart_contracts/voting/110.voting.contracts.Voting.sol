// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting{
    event AddedCandidate(uint candidateId);
    address owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner,"Sender is not contract owner");
        _;
    }
    struct Voter{
        bytes32 uId;
        uint votedCandidateId;        
    }
    struct Candidate{
        bytes32 name;
        bytes32 partyName;
    }
    uint numOfCandidates;
    uint numOfVoters;
    mapping (uint => Candidate) candidates;
    mapping (uint => Voter) voters;
    

    function getNumOfCandidates() public view returns(uint){
        return numOfCandidates;
    }
    function getNumOfVoters() public view returns(uint){
        return numOfVoters;
    }
    function getCandidate(uint cId) public view returns(uint,bytes32,bytes32){
        return (cId,candidates[cId].name,candidates[cId].partyName);
    }
    function totalVotes(uint cId) public view returns(uint){
        uint total=0;
        for(uint i = 0; i <numOfVoters ; i++){
            if(voters[i].votedCandidateId == cId){
                total++;
            }
        }
        return total;
    }


    function addCandidate(bytes32 name, bytes32 partyName) onlyOwner public{
        uint cId = numOfCandidates++;
        candidates[cId] = Candidate(name,partyName);
        emit AddedCandidate(cId);
    }
    function vote(bytes32 uId,uint votedCandidateId) public{
        uint voterId = numOfVoters++;
        voters[voterId] = Voter(uId,votedCandidateId);
    }
}