pragma solidity 0.5.16;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // fetch candidates key uint - candidate value pair in a map
    mapping(uint => Candidate) public candidates;

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Read/write candidate
    string public candidate;

    // Store Candidates Count
    uint public candidatesCount;


    event votedEvent (
        uint indexed _candidateId
    );
    
    // Constructor
    constructor() public {
        addCandidate("Donald J. Trump");
        addCandidate("Joe Biden");
    }

    // add candidate into the map
    // increment the candidate counter cache to denote that a new candidate has been added. 
    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // vote given candidate id 
    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}