pragma solidity ^0.5.8;

contract Election{

    //Structure to hold the candidate details
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    event votedEvent(uint indexed _candidateID);

    // store accounts that have voted
    mapping(uint => bool) public voters;

    // Read/Write candidates
    mapping(uint => Candidate) public candidates;

    // Store the number of candidates
    uint public candidatesCount;

    // Function for adding candidates to the election
    function addCandidates(string memory _name) private{
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateID) public{
        require(!voters[uint256(msg.sender)]);

        require(_candidateID > 0 && _candidateID <= candidatesCount);
        // record the voter as voted
        voters[uint256(msg.sender)] = true;
        // update candidate vote
        //reference the mapping of candidate
        candidates[_candidateID].voteCount++;
        emit votedEvent(_candidateID);
    }

    constructor() public{
        addCandidates("candidate_1");
        addCandidates("candidate_2");
    }
}
