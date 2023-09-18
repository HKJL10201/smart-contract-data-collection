// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingEngine is Ownable {
    uint256 public feeRate = 10000000000000000; // voting fee in wei
    uint256 public voteTime = 3 days; // duration of voting
    uint256 public percentFee = 10; // percent of voting fee amount for owner
    uint256 public feeSum; // Total owner earning 

    struct Voting {
        address[] applicants;
        uint256[] votes;
        uint256 startAt;
        uint256 endsAt;
        address winner;
        uint256 prizeEther;
        bool stopped;
    }
    mapping(address => mapping(uint256 => bool)) public electors; 

    mapping(uint256 => Voting) public votings;
    uint256 public votingCounter; // counter of the total number of votings

    event VotingCreated(uint256 indexed votingId, uint256 startAt, uint256 endsAt);
    event VotingEnded(uint256 indexed votingId, address winner, uint256 prizeEther);

    function addVoting(address[] memory applicants) external onlyOwner {
        Voting storage newVoting = votings[votingCounter++];

        newVoting.startAt = block.timestamp;
        newVoting.endsAt = newVoting.startAt + voteTime;

        for(uint256 i = 0; i < applicants.length; i++) {
            newVoting.applicants.push(applicants[i]);
            newVoting.votes.push(0);
        }

        emit VotingCreated(votingCounter - 1, newVoting.startAt, newVoting.endsAt);
    }

    function vote(uint256 indexVoting, uint256 indexApplicant) external payable {
        require(msg.value == feeRate, "Incorrect fee amount!");
        require(indexVoting < votingCounter, "Incorrect voting index!");
        require(!votings[indexVoting].stopped, "Voting already stopped!");
        require(votings[indexVoting].endsAt > block.timestamp, "Voting time is ended!");
        require(electors[msg.sender][indexVoting] == false, "Elector already voted!");

        electors[msg.sender][indexVoting] = true;
        votings[indexVoting].votes[indexApplicant]++;
        votings[indexVoting].prizeEther += msg.value;
    }

    function finish(uint256 votingIndex) external {
        require(!votings[votingIndex].stopped, "Voting already stopped!");
        require(votings[votingIndex].endsAt < block.timestamp, "Voting time is not ended!");
        require(votingIndex < votingCounter, "Incorrect voting index!");

        uint256 winningVoteCount = 0;
        address winner;
        for (uint i = 0; i < votings[votingIndex].votes.length; i++) {
            if (votings[votingIndex].votes[i] > winningVoteCount) {
                winningVoteCount = votings[votingIndex].votes[i];
                winner = votings[votingIndex].applicants[i];
            }
        }
        votings[votingIndex].winner = winner;
        payable(winner).transfer((votings[votingIndex].prizeEther * (100 - percentFee)) / 100);
        feeSum += (votings[votingIndex].prizeEther * percentFee) / 100;

        votings[votingIndex].stopped = true;
        emit VotingEnded(votingIndex, winner, votings[votingIndex].prizeEther);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(feeSum);
        feeSum = 0;
    }
    
    function getApplicants(uint256 indexVoting) public view returns (address[] memory applicants) {
        return votings[indexVoting].applicants;
    }
        
    function getVotes(uint256 indexVoting) public view returns (uint256[] memory votes) {
        return votings[indexVoting].votes;
    }

    function getEndsAt(uint256 indexVoting) public view returns (uint256 startAt, uint256 endsAt) {
        return (votings[indexVoting].startAt, votings[indexVoting].endsAt);
    }
    
    function getWinner(uint256 indexVoting) public view returns (address winner) {
        return votings[indexVoting].winner;
    }

    function isVotingStopped(uint256 indexVoting) public view returns (bool stopped) {
        return votings[indexVoting].stopped;
    }
}

