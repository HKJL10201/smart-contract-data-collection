pragma solidity ^0.5.0;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Read/write candidates
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    constructor () public {
        // TODO set default candidates
        addCandidate("Carrot");
        addCandidate("Potato");
    }

    function addCandidate (
        string memory _name
    ) private {
        // TODO store new candidate in state variables
                candidatesCount++;
        candidates[candidatesCount] =
            Candidate(candidatesCount, _name, 0);
    }

    function vote (
 uint _candidateId
    ) public {
        // TODO check that account hasn't voted before
        require(
            !voters[msg.sender]);
        // require a valid candidate
        require(
            _candidateId > 0 &&
            _candidateId <= candidatesCount);

        // TODO record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;
    }
}
