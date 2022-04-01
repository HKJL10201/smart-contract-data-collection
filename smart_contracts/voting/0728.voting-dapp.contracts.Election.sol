pragma solidity ^0.8.0;

contract Election {
    struct Candidate {
        uint256 id;
        string name;
    }

    struct Votant {
        address votant_address;
        string name;
        string document_id;
    }

    Candidate[3] candidates;
    mapping(address => Votant) public votants;
    mapping(address => uint256) votes;

    constructor() {
        addCandidate(0, "Candidate 1");
        addCandidate(1, "Candidate 2");
        addCandidate(2, "Candidate 3");
    }

    function addCandidate(uint256 id, string memory name) private {
        candidates[id] = Candidate(id, name);
    }

    function getVotant() public view returns (Votant memory votant) {
        votant = votants[msg.sender];
    }

    function registerVotant(string memory name, string memory document_id)
        public
        returns (Votant memory votant)
    {
        // TODO is already registered?
        votant = Votant(msg.sender, name, document_id);
        votants[msg.sender] = votant;
    }

    function vote(uint256 candidate_id)
        public
        returns (Candidate memory candidate)
    {
        // TODO is registered already?
        votants[msg.sender];
        // TODO voted already?
        candidate = candidates[candidate_id];
        // TODO validate candidate id is correct
        votes[msg.sender] = uint256(candidate_id);
        return candidate;
    }
}
