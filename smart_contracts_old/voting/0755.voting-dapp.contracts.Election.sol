pragma solidity >=0.4.2;

contract Election {
    // Model a candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    // store candidates
    //  fetch candidates
    mapping(uint => Candidate) public candidates;

    // store candidates count
    uint public candidatesCount;

    // Store accounts that voted
    mapping(address => bool) public voters;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    constructor() public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        // Make sure voter has not voted before
        require(!voters[msg.sender]);

        // Require valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record voter has voted
        voters[msg.sender] = true;

        // update candidate votecount
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }
}
