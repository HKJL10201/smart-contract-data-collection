// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Election{
    
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    
    mapping (uint => Candidate) public candidates;
    uint public candidatecount;
    mapping (address => bool) public voter;
    
    event eventVote(
        uint indexed _candidateid
        );
    
    constructor() {
        addCandidate("Trump");
        addCandidate("Biden");
    }
    
    function addCandidate(string memory _name) public{
        candidatecount++;
        candidates[candidatecount] = Candidate(candidatecount, _name, 0);
    }
    
    function vote(uint _candidateid) public{
        require(!voter[msg.sender]);
        require(_candidateid > 0 && _candidateid <= candidatecount);
        
        voter[msg.sender] = true;
        candidates[_candidateid].voteCount ++;
        
        emit eventVote(_candidateid);
    }
    function getcount(uint _candidateid) public view returns(uint) {
    //    require(candidates[_candidateid].voteCount);
        return( candidates[_candidateid].voteCount);
        }
}