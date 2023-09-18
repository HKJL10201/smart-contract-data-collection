pragma solidity ^0.5.16;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;
    mapping(address => uint) public voterAge;
    mapping(address => uint) public voter_candidate;
    // mapping(address => uint ) public num_votes;
    // mapping(address => uint ) public  num_retracts;

    // Read/write candidates
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    // ageUpdate event
    event ageUpdateEvent (
        uint indexed new_age
    );
    // retractEvent event
    event retractEvent (
        address indexed voterAdress
    );

    constructor () public {
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

        require(voterAge[msg.sender] >= 18);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;
        // num_votes[msg.sender] += 1;

        voter_candidate[msg.sender] = _candidateId;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // emitting voted event 
        emit votedEvent(_candidateId);
    }

    
    function updateMyAge(uint newAge) public {
        // Usingg this function a voter can update his/her vote in the database
        voterAge[msg.sender] = newAge;

        emit ageUpdateEvent(newAge);

    }

    function retractMyVote() public{

        require(voters[msg.sender]);

        voters[msg.sender] = false;
        // num_retracts[msg.sender] += 1;

        uint id = voter_candidate[msg.sender];

        candidates[id].voteCount --;

        emit retractEvent(msg.sender);

    }

}