// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Voting {

    // Type to represent a single voter
    struct Voter {
        bool canVote;   // Wether the user has the right to vote
        bool hasVoted;  // Wether the user has already voted
        int vote;       // Index of voted candidate or `-1` if user has not voted yet 
    }

    // Type to represent a single candidate
    struct Candidate {
        string name;    // Name of the candidate
        uint voteCount; // Total votes
    }

    // List of candidates
    Candidate[] public candidates;
    uint public totalCandidates;

    // List of voters
    mapping(address => Voter) public voters;
    uint public totalVoters;

    // The chair person of the election
    address public chairperson;

    // Voting time range
    uint256 public votingTimeStart;
    uint256 public votingTimeEnd;

    constructor() {
        chairperson = msg.sender;
    }

    /**
     * Set when the voting takes place
     */
    function setVotingTime(uint256 start, uint256 end) external {
        require(msg.sender == chairperson, 'Only the chair person allowed!');

        votingTimeStart = start;
        votingTimeEnd = end;
    }

    /**
     * Add a single candidate to the list
     */
    function addCandidate(string memory name) external {
        require(msg.sender == chairperson, 'Only the chair person allowed!');
        require(isVotingTime() == false, 'Voting has been started!');

        candidates.push(Candidate(name, 0));
        totalCandidates++;
    }

    /**
     * Get the candidate's name and the total votes
     */
    function getCandidate(uint index) public view returns (string memory, uint) {
        Candidate memory candidate = candidates[index];
        return (candidate.name, candidate.voteCount);
    }

    /**
     * Retrieve all of the candidates and the total votes
     */
    function getCandidates() public view returns (string[] memory, uint[] memory) {
        string[] memory names = new string[](totalCandidates);
        uint[] memory voteCounts = new uint[](totalCandidates);
        for (uint i = 0; i < totalCandidates; i++) {
            names[i] = candidates[i].name;
            voteCounts[i] = candidates[i].voteCount;
        }
        return (names, voteCounts);
    }

    /**
     * Give the right for an address to vote
     */
    function addVoter(address addr) external {
        require(msg.sender == chairperson, 'Only the chair person allowed!');
        require(isVotingTime() == false, 'Voting has been started!');
        require(voters[addr].canVote == false, 'The voter already exist.');
        require(voters[addr].hasVoted == false, 'The voter already voted.');

        voters[addr].canVote = true;
        voters[addr].vote = -1;
        totalVoters++;
    }

    /**
     * Helper function to check if now is the voting time
     */
    function isVotingTime() public view returns (bool) {
        if (votingTimeStart <= block.timestamp && block.timestamp <= votingTimeEnd) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Give your vote to the chosen candidate index
     */
    function vote(uint candidateIndex) external {
        require(voters[msg.sender].hasVoted == false, 'The voter has already voted.');
        require(isVotingTime(), 'Voting time has ended.');
        require(candidateIndex < totalCandidates, 'Invalid candidate.');

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].vote = int(candidateIndex);
        candidates[candidateIndex].voteCount++;
    }

    /**
     * Retrieve the name of the winning candidate
     */
    function getWinningCandidate() public view returns (string memory name) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < totalCandidates; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                name = candidates[i].name;
            }
        }
    }
}
