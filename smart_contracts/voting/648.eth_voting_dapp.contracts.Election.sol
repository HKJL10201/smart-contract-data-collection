pragma solidity >=0.4.22 <0.8.0;

contract Election {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    event votedEvent (
        uint indexed _candidateId
    );

    // solidity mapping, associative array or hash, associates key-value pairs
    // Read/write candidates
    mapping(uint => Candidate) public candidates;    

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates Count
    uint public candidatesCount;

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

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


    // Constructor
    constructor () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

}

