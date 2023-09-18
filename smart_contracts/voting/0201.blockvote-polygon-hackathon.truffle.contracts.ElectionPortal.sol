// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// Portal contract
contract ElectionPortal {

    // Election states
    enum State {
        NotStarted,
        InProgress,
        Ended
    }

    // Candidate data structure
    struct Candidate {
        uint256 id;
        uint256 voteCount; // Candidate vote count
        string name; // Candidate name
        string imageURL; // Candidate image URL
    }

    // Election data structure:
    struct Election{
        uint256 id;
        string title;
        Candidate [] candidates; 
        State state;
        address owner;
        mapping(address => bool) eligible; // For checking if address is an eligible voter
        mapping(address => bool) hasVoted; // For checking if voter has already voted
    }

    Election [] public elections; // Array with all elections

    // Returns array of election titles
    function getElections() public view returns (string [] memory) {
        string [] memory _titles = new string[](elections.length); 
        for(uint i=0; i < elections.length; i++){
            _titles[i] = elections[i].title;
        }
        return _titles;
    }

    // Returns election title
    function getElectionTitle(uint256 _electionId) public view returns (string memory _title) {
        _title = elections[_electionId].title;
    }


    // Returns candidate structs of a specific election
    function getCandidates(uint _electionId) public view returns (Candidate [] memory _candidates) {
        _candidates = elections[_electionId].candidates;
    }

    // Check if msg sender is the election owner or not:
    function isOwner(uint _electionId) public view returns (bool) {
        if (elections[_electionId].owner == msg.sender) {
            return true;
        }
        return false;
    }
    
    // Check if msg sender has already voted in given election:
    function hasVoted(uint _electionId) public view returns (bool _hasVoted) {
        _hasVoted = elections[_electionId].hasVoted[msg.sender];
    }
    
    // Returns true if msg sender is eligible to vote in given election
    function isEligible(uint _electionId) public view returns (bool _eligible) {
        _eligible = elections[_electionId].eligible[msg.sender];
    }

    // Vote for a specific candidate in a specific election
    function vote(uint _electionId, uint _candidateId) public {
        require(elections[_electionId].state == State.InProgress, "Election not in progress");
        require(isEligible(_electionId), "Ineligible for election");
        require(!hasVoted(_electionId), "Already voted");

        elections[_electionId].candidates[_candidateId].voteCount++;
        elections[_electionId].hasVoted[msg.sender] = true;
    }   

    // Return state of the election:
    function getElectionState(uint _electionId) public view returns (uint){
        if (elections[_electionId].state == State.NotStarted){
            return 0;
        }
        else if (elections[_electionId].state == State.InProgress){
            return 1;
        }
        else{
            return 2;
        }
    }

    // Creates a new election
    function createElection(string memory _title, 
                            string [] memory _candidateNames, 
                            string [] memory _candidateimageURLs,
                            address [] memory _eligibleVoters) public { 
        require(_candidateNames.length >= 2, "Candidates less than 2");
        require(_candidateNames.length == _candidateimageURLs.length, "Every candidate must have an image URL");
        require(_eligibleVoters.length >= 1, "No voters");

        // Instantiate new election with parameters
        uint256 idx = elections.length;
        elections.push();
        Election storage _election = elections[idx];
        _election.title = _title;
        _election.state = State.NotStarted;
        _election.owner = msg.sender;

        // Creates candidate structs for the election 
        for(uint i=0; i < _candidateNames.length; i++){
            Candidate memory _candidate;
            _candidate.id = i; 
            _candidate.voteCount = 0; 
            _candidate.name = _candidateNames[i]; 
            _candidate.imageURL = _candidateimageURLs[i];
            _election.candidates.push(_candidate); 
        }

        // Give all eligible voters the right to vote
        for(uint i=0; i < _eligibleVoters.length; i++){
            _election.eligible[_eligibleVoters[i]] = true;
        }
    }

    // Sets given election state to InProgress
    function startElection(uint _electionId) public {
        require(msg.sender == elections[_electionId].owner, "Only owner can start the election.");
        require(elections[_electionId].state != State.InProgress, "Election is already in progress.");
        require(elections[_electionId].state != State.Ended, "Election has ended.");

        elections[_electionId].state = State.InProgress;
    }

    // Sets given election state to Ended
    function endElection(uint _electionId) public {
        require(msg.sender == elections[_electionId].owner, "Only owner can end the election.");
        require(elections[_electionId].state == State.InProgress, "Election is not in progress.");
        
        elections[_electionId].state = State.Ended;
    }

}