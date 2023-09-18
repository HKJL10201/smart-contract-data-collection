pragma solidity 0.5.16;

contract Election{

    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

 // voted event
    event votedEvent (
        uint indexed _candidateId
    );
    mapping(uint =>Candidate) public candidates;
    mapping(address => bool) public voters;
    uint public candidatesCount;

  
    constructor () public{
        addCandidate("Janez Janša");
        addCandidate("Borut Pahor");
        
    }

    function addCandidate (string memory  _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }


    function vote(uint _candidateId) public {
    
    require(!voters[msg.sender], "Ste že volili");

    
    require(_candidateId > 0 && _candidateId <= candidatesCount, "Napačen ID kandidata");

    
    voters[msg.sender] = true;

    
    candidates[_candidateId].voteCount++;

    emit votedEvent(_candidateId);
}
    
}