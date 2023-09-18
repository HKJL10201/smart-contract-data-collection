// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Election {
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    
    mapping(uint=>Candidate) public candidates;
    uint public candidatecount;
    mapping(address=>bool) public voter;
    
    event eventVote(
        uint indexed _candidateid
        );
    
     constructor()  {
         addCandidate("Donald J. Trump");
         addCandidate("Bernie Sanders");
         addCandidate("Joseph R. Biden Jr.");
         addCandidate("Tulsi Gabbard");
         addCandidate("Emirhan Dikci");
    }
    
    
    function addCandidate(string memory _name) public {
        candidatecount++;
        candidates[candidatecount]=Candidate(candidatecount,_name,0);
    }
    function vote(uint _candidateid) public {
        require(!voter[msg.sender]);
        require(_candidateid>0 && _candidateid<=candidatecount);
        
        voter[msg.sender]=true;
        candidates[_candidateid].voteCount ++;
        
        emit eventVote(_candidateid);
    }
}
