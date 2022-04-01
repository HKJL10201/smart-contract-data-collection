pragma solidity ^0.5.0;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;        // unsigned integer type
        string name;    // string type
        uint voteCount; // unsigned integer type
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Read/write Candidates
    /**
     * A mapping in Solidity is like an associative array or a hash, 
     * that associates key-value pairs
     */
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;


    /**
     * Events are made possible on Contracts
     */
    event votedEvent (
        uint indexed _candidateId
    );

    // Constructor
    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    /**
     * Adds a candiate in candiates mapping
     * param string _name
     */
    function addCandidate(string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    /**
     * Adds a vote in the system
     * param uint _candidateId
     */
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