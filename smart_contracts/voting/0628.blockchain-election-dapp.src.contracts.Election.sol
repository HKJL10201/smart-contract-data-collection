pragma solidity ^0.5.0;


contract Election {
    // Model a candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Store candidates that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidates
    mapping(uint256 => Candidate) public candidates;
    // Store Candidates Count
    uint256 public candidatesCount;

    //voted event
    event votedEvent(uint256 indexed _candidateId);

    constructor() public {
        addCandidate("John Doe");
        addCandidate("Jane Doe");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Invalid Candidate"
        );

        // record that voter has voted
        voters[msg.sender] = true;

        //update the vote count
        candidates[_candidateId].voteCount++;

        //trigger voted event
        emit votedEvent(_candidateId);
    }
}
