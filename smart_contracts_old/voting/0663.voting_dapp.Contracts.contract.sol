// SPDX-Liscence-Identifier: MIT

pragma solidity ^0.8.11;

contract Election{
    
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    
    constructor() {
        addCandidate("Donald Trump");
        addCandidate("Joe Biden");
    }

    // public visibility for both candidates AND voters
    mapping (uint => Candidate) public candidates;
    uint public candidatecount;
    mapping (address => bool) public voter;
    
    event eventVote(uint indexed _candidateid);

    // adding candidates    
    function addCandidate(string memory _name) public{
        candidatecount++;
        candidates[candidatecount] = Candidate(candidatecount, _name, 0);
    }

    // voting function
    function vote(uint _candidateid) public{
        require(!voter[msg.sender]);
        require(_candidateid > 0 && _candidateid <= candidatecount);
        
        voter[msg.sender] = true;
        candidates[_candidateid].voteCount++;
        
        emit eventVote(_candidateid);
    }

    function getcount(uint _candidateid) public view returns(uint) {
        return( candidates[_candidateid].voteCount);
    }
}
