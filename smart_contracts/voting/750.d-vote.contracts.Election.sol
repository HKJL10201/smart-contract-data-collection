pragma solidity >=0.5.16;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        string party;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address=> bool) public voters;
    // Store and fetch Candidate
    mapping(uint=> Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    constructor () public {
        addCandidate("Candidate1","Party1");
        addCandidate("Candidate2","Party2");
        addCandidate("Candidate3","Party3");
        addCandidate("Candidate4","Party4");
        addCandidate("Candidate5","Party5");
        addCandidate("NOTA","None of the above");
    }

    function addCandidate (string memory name,string memory party) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name,party, 0);
    }

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId>0 && _candidateId<=candidatesCount);

        // record that voter has voted
        voters[msg.sender]= true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}