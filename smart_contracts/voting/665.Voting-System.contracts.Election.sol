pragma solidity >=0.4.2;

contract Election {
    //structure for a candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    //accounts that voted
    mapping(address => bool) public voters;

    // store and retrieve the candidates
    mapping(uint256 => Candidate) public candidates;

    uint256 public candidatesCount;

    event votedEvent(uint256 indexed _candidateId);

    //Constructor
    constructor() public {
        addCandidate("John Smith");
        addCandidate("John Doe");
        addCandidate("James Dean");
        addCandidate("Robert Johnson");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender]);

        // candidate is valid.
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // has voted.
        voters[msg.sender] = true;

        // increment the vote count
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }
}
