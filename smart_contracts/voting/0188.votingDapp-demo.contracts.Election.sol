pragma solidity ^0.5.0;

contract Election {
    
    //candidates data
    
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
      mapping(uint => Candidate) public candidates;
      
      uint public candidatesCount ;//1
      
      mapping(address => bool) public voters;
      
       event votedEvent (
        uint indexed _candidateId
    );
    
    //function to fetch the candidates
    
    constructor() public {
         addCandidate("Krishna");
         addCandidate("Ram");
    }
    

    function addCandidate(string memory _name) private {
        
        candidatesCount ++;//2
        
        candidates[candidatesCount ] = Candidate(candidatesCount ,_name,0);
        
    }
    
    
    
    function vote(uint _candidateId) public {
        
        require(!voters[msg.sender]);
        
        require(_candidateId > 0 && _candidateId < candidatesCount );
        
        voters[msg.sender] = true;
        
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
        
    }
    
}