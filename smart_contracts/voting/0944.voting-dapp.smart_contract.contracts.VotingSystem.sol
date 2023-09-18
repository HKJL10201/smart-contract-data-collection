// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    struct Candidate {
        string party;
        string name;
        uint256 voteCount;
    }

    mapping(address => bool) public hasVoted;
    mapping(string => uint256) public candidateIdByParty;  // Added mapping to associate party with candidate ID
    Candidate[] public candidates;

    event VoteCasted(uint256 indexed candidateId, address voter);

    constructor() {
        addCandidate("APC", "Tinubu");
        addCandidate("PDP", "Atiku");
        addCandidate("LP", "Peter Obi");
    }

    function addCandidate(string memory _party, string memory _name) internal {  // Modified to add candidate and associate party with candidate ID
        uint256 candidateId = candidates.length;
        candidates.push(Candidate(_party, _name, 0));
        candidateIdByParty[_party] = candidateId;
    }

    function castVote(string memory _party) external {
        uint256 candidateId = candidateIdByParty[_party];  // Modified to get candidate ID based on party
        require(candidateId > 0, "Invalid party");  // Check if the party is valid
        require(!hasVoted[msg.sender], "Already voted");

        candidates[candidateId].voteCount++;
        hasVoted[msg.sender] = true;

        emit VoteCasted(candidateId, msg.sender);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 _candidateId) external view returns (string memory, uint256) {
        require(_candidateId < candidates.length, "Invalid candidate ID");

        Candidate memory candidate = candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }
}
