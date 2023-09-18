pragma solidity >=0.4.22 <0.9.0;

contract Election {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Save who has voted
    mapping(address => bool) public voters;

    // Read/Write candidates
    mapping(uint256 => Candidate) public candidates;

    // Used to access to the candidates mapping
    uint256 public candidateCount;

    // Notify when someone votes
    event VotedEvent(uint256 indexed candidateId);

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        // An address can vote only once
        require(!voters[msg.sender]);

        // Vote for a valide candidate
        require(_candidateId > 0 && _candidateId <= candidateCount);

        // Has voted
        voters[msg.sender] = true;

        // Apply the vote in the candidate count
        candidates[_candidateId].voteCount++;

        // Triggger vote event
        emit VotedEvent(_candidateId);
    }
}
