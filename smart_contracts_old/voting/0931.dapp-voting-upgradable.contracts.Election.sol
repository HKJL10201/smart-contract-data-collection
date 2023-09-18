pragma solidity >=0.4.20 <0.6.0;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;
    uint public PersonVote;
    address public admin;

    // event LogaddPerson(string name);
    // event LoggetPersonById(uint id);
    
    // voted event
    event votedEvent (
        uint indexed _candidateId
    );


    // step 1: Not upgradable
    // constructor() public {
    //     addCandidate("Candidate 1");
    //     addCandidate("Candidate 2");
    // }

    // step 2: For upgradable step 7: Add candidate for init
    function initialize() public {
        PersonVote = 0;
        admin = msg.sender;
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }
    
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
}
