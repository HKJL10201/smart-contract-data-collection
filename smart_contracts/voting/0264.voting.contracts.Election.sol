pragma solidity ^0.4.22;

contract Election {

    struct Candidate {
        uint256 id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint public candidatesCount;

    event votedEvent (
        uint indexed _candidateId
    );

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
    }

    function Election() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function vote(uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount ++;
        votedEvent(_candidateId);
    }
}