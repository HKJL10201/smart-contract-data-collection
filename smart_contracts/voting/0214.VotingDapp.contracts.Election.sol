pragma solidity >=0.4.2;


contract Election {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Store candidates
    mapping(uint256 => Candidate) public candidates;

    // Store and track accounts that already voted
    mapping(address => bool) public voters;

    // Voted event
    event votedEvent(uint256 indexed _candidateId);

    uint256 public candidatesCount;

    constructor() public {
        addCandidate("Elizabeth Warren");
        addCandidate("Joe Biden");
        addCandidate("Andrew Yang");
        addCandidate("Pete Buttigiege");
        addCandidate("Bernie Sanders");
        addCandidate("Cory Booker");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        // Check that voter hasn't already voted
        require(!voters[msg.sender], "Already Voted sorry");
        // Check candidate being voted or is valid
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Candidate is invalid"
        );
        // record that voter has voted
        voters[msg.sender] = true;
        // update candidate vote count
        candidates[_candidateId].voteCount++;

        // Trigger the voted even
        emit votedEvent(_candidateId);
    }
}
