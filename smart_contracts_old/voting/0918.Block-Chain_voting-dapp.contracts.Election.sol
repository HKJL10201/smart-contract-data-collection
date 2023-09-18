pragma solidity >=0.4.22 <0.7.0;

contract Election {

    event votedEvent(
        uint indexed _candidateId
    );

    uint public candidatesCount=0;

    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping (address => bool) public voters;
    function addCandidate (string memory _name) internal {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public{
        require(!voters[msg.sender]);
        require (_candidateId > 0 && _candidateId <= candidatesCount);
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit votedEvent(_candidateId);
    }

    constructor () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");

    }
}