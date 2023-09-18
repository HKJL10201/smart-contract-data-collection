// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Voting {
    string public name;
    string public description;
    
    struct Candidate {
        uint id;
        string name;
        string about;
        uint voteCount;
    }
    
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;     //Storing address of those voters who already voted
    uint public candidatesCount = 0;     //Number of candidates in standing in the voting
    
    constructor(string[] memory _name, string[][] memory _candidates) public {
        require(_candidates.length > 0, "There should be at least 1 candidate");
        name = _name[0];
        description = _name[1];
        for (uint i = 0; i < _candidates.length; i++) {
            addCandidate(_candidates[i][0], _candidates[i][1]);
        }
    }
    
    function addCandidate(string memory _name, string memory _about) private {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _about, 0);
        candidatesCount++;
    }
    
    function vote(uint _candidate) public {
        require(!voters[msg.sender], "Already voted");
        require(
            _candidate < candidatesCount && _candidate >= 0,
            "Invalid candidate"
        );
        voters[msg.sender] = true;
        candidates[_candidate].voteCount++;
    }
    
    function getVoterStatus(address _voter) public view returns (string memory) {
        require(_voter != address(0), "Invalid address");
        if (voters[_voter]) {
            return "Already voted";
        } else {
            return "Not voted yet";
        }
    }
    
    function getVotingDetails() public view returns (string memory, string memory, uint) {
        return (name, description, candidatesCount);
    }
    
    function getCandidate(uint _candidateId) public view returns (uint, string memory, string memory, uint) {
        require(_candidateId < candidatesCount && _candidateId >= 0, "Invalid candidate");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.about, candidate.voteCount);
    }
    
    function getVotingWinner() public view returns (uint, string memory, uint) {
        require(candidatesCount > 0, "No candidates available");
        uint maxVotes = 0;
        uint winnerId;
        for (uint i = 0; i < candidatesCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerId = candidates[i].id;
            }
        }
        Candidate memory winner = candidates[winnerId];
        return (winner.id, winner.name, winner.voteCount);
    }
}
