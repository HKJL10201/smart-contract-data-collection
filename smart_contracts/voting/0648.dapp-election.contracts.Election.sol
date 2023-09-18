pragma solidity 0.5.0;

contract Election {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        address donations;
    }

    event votedEvent (
        uint indexed _candidateId
    );

    mapping(uint => Candidate) public candidates;
    
    mapping(address => bool) public hasVoted;


    uint public candidatesCount;

    constructor() public {
        candidatesCount = 0;
        addCandidate("Candidate 1", 0xD538dd5Eb9650017cB6DbFDdF2590B3a62B67780);
        addCandidate("Candidate 2", 0x66580407a5921471e574F8E737143985Dee05BD9);
    }

    function vote(uint _candidateId) public {
        require(!hasVoted[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        hasVoted[msg.sender] = true;
        candidates[_candidateId].voteCount ++;
        emit votedEvent(_candidateId);
    }

    function addCandidate (string memory _name, address _addr) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _addr);
    }    
}