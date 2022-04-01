pragma solidity ^0.5.0;

contract Election {

    event votedEvent(
        uint indexed _candidateId
        );

    // Model candidate
    struct Candidate{
        uint Id;
        string name;
        uint voteCount;

    }

    //Read/Write Candidates
    mapping(uint => Candidate) public candidates;

    //keep track of candidates added
    uint public candidateCount;

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Constructor
    constructor () public {
        //candidate = "Candidate 1";
        addCandidate("Martin");
        addCandidate("Alex");
        addCandidate("Tobby");
    }

    //Add a candidate
    function addCandidate(string memory _name) private {
        candidateCount ++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    //Vote

    function vote (uint _candidateId) public {
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidateCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        //fire voted event
        emit votedEvent(_candidateId);
    }


}