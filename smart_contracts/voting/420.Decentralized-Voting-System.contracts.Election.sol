pragma solidity 0.4.25;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        string party;
        uint voteCount;
    }

    

    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;             
    // Store Candidates Count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    constructor () public {
        addCandidate("Narendra Modi","BJP");
        addCandidate("Rahul Gandhi","INC");
        addCandidate("Arvind Kejriwal","AAP");
        addCandidate("Sharad Pawar","NCP");
        addCandidate("Mamata Banerjee","TMC");
        
        
        
    }

    function addCandidate (string _name , string _party) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _party, 0);
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
