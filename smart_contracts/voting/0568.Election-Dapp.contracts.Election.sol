pragma solidity >=0.4.17;

contract Election{
    struct candidate{
        uint id;
        string name;
        uint votecount;
    }
    mapping(address => bool) public voters;
    mapping(uint => candidate) public candidates;
    uint public candidatesCount;
     
     event votedEvent (
         uint indexed _candidateId
     );
    constructor () public{
         addCandidate("candidate 1");
         addCandidate("candidate 2");
    }

    function addCandidate (string memory _name) private 
    {
        candidatesCount ++;
        candidates[candidatesCount] = candidate(candidatesCount, _name, 0); 
    }

    function vote (uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        voters[msg.sender]=true;
        candidates[_candidateId].votecount++;
        
       emit votedEvent(_candidateId);
    }
}