pragma solidity ^0.5.0;

contract Voting {
    
    struct Candidate {
        
        uint id;
        string name;
        uint voteCount;
    }
    
    mapping (uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    
    uint public candidatecount;
    
    event eventVote(uint indexed _candidateid);
    
    constructor () public {
        addCandidate("Raja");
        addCandidate("Neha");
        
    }
    
    function addCandidate (string memory _candidateName) private {
        candidatecount++;
        candidates[candidatecount] = Candidate(candidatecount,_candidateName,0);
        
    }
    
    function vote (uint _candidateid) public  {
        
        require(!voters[msg.sender]);
        require(_candidateid>0 && _candidateid<=candidatecount);
    
        voters[msg.sender]=true;
        candidates[_candidateid].voteCount++;
        emit eventVote(_candidateid);
    }
}