pragma solidity >=0.4.22 <0.6.2;

contract Election {
    string public candidate;

    event votedEvent (
        uint indexed _candidateId
    ); 

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    
    uint public candidatesCount;

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount ++;
        emit votedEvent(_candidateId);
    }

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }


}