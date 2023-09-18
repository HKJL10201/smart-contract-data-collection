// Step 1: Declare a pragma statment for the compiler
pragma solidity >= 0.4.22 <0.7.0;

// Step 2: Define the contract itself
contract Election {
    
    // Step 3: Declare a struct to contain candidates
    struct Candidate {
        uint id;
        string name;
        uint votes;
    }
    
    // Step 4: Declare all necessary contract variables
    mapping(uint=>Candidate) public candidates;
    mapping(address=>bool) public voters;
    uint public candidatesCount;
    uint maxCandidates;
    bool ended;
    address owner;
    
    // Step 5: Declare a constructor for instantiating the contract
    constructor (
        uint _maxCandidates
    ) public {
        require(_maxCandidates >= 2);
        maxCandidates = _maxCandidates;
        ended = false;
        owner = msg.sender;
    }
    
    // Step 6: Declare an event for notfifying that a candidate was added
    event NewCandidate (
        uint indexed _candidateId,
        string _name,
        uint _votes
    );
    
    // Step 7: Declare an event for notifying that a 
    event VoteCast (
        uint indexed _candidateId
    );
    
    // Step 8: Declare a method for adding candidates to the contract
    function addCandidate(string memory name) public {
        require(!ended);
        require(msg.sender == owner);
        require(candidatesCount < maxCandidates);
        
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, 0);
        emit NewCandidate(
            candidates[candidatesCount-1].id, 
            candidates[candidatesCount-1].name, 
            candidates[candidatesCount-1].votes
        );
    }
    
    // Step 9: Declare a method allowing people to vote on candidates.
    function castVote(uint id) public {
        require(!ended);
        require(id > 0 && id <= candidatesCount);
        require(!voters[msg.sender]);
        
        voters[msg.sender] = true;
        candidates[id].votes++;
        emit VoteCast(id);
    }
    
    // Step 10: Declare a method for ending the voting process
    function endVoting() public {
        require(!ended);
        ended = true;
    }
    
    // Step 11: Declare a getter function for retrieving candidate information
    function getCandidate(uint id) public view returns (uint, string memory, uint) {
        require(id > 0 && id <= candidatesCount);
        Candidate memory candidate = candidates[id];
        return (candidate.id, candidate.name, candidate.votes);
    }
    
    // Step 12: Declare a getter function for retrieving a candidates name
    function getName(uint id) public view returns (string memory) {
        require(id > 0 && id <= candidatesCount);
        return candidates[id].name;
    }
    
    // Step 13: Declare a getter function for getting a candidates votes
    function getVotes(uint id) public view returns (uint) {
        require(id > 0 && id <= candidatesCount);
        return candidates[id].votes;
    }
}

