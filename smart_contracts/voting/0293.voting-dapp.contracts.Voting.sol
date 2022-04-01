// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Voting is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private proposalCounter;

    uint public winningProposalId;
    WorkflowStatus private votingStatus = WorkflowStatus.RegisteringVoters;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    mapping(address => Voter) public voters;
    mapping(uint => Proposal) public proposals;


    /// @notice better modifier performance
    function requireStatus(WorkflowStatus status) internal view {
        require(votingStatus == status, string(abi.encodePacked("Require ", getVotingStatusString(status), " status !")));
    }   

    modifier onlyStatus(WorkflowStatus status) {
        requireStatus(status);
        _;
    }

    /// @notice better modifier performance
    function requireRegisteredVoter() internal view {
        require(voters[msg.sender].isRegistered, string(abi.encodePacked("Not a registered voter: ", msg.sender)));
    }

    modifier onlyRegisteredVoter() {
        requireRegisteredVoter();    
        _;
    }

    /*
        Getters
    */

    function getVotingStatus() external view returns (string memory) {
        return getVotingStatusString(votingStatus);
    }

    // Returns a string instead of the uint of the enumeration 
    function getVotingStatusString(WorkflowStatus status) internal pure returns (string memory) {
        if (status == WorkflowStatus.ProposalsRegistrationStarted) {
            return "ProposalsRegistrationStarted";
        } else if (status == WorkflowStatus.ProposalsRegistrationEnded) {
            return "ProposalsRegistrationEnded";
        } else if (status == WorkflowStatus.VotingSessionStarted) {
            return "VotingSessionStarted";
        } else if (status == WorkflowStatus.VotingSessionEnded) {
            return "VotingSessionEnded";
        } else if (status == WorkflowStatus.VotesTallied) {
            return "VotesTallied";
        } else {
            return "RegisteringVoters";
        }
    }

    function getWinner() external view returns (Proposal memory) {
        return proposals[winningProposalId];
    }

    function getProposalCount() external view returns (uint) {
        return proposalCounter.current();
    }
    
    /*
        Set of functions to handle participation, voting proposals and vote
    */

    // Whitelist voter with his address
    function registerVoter(address voter) external onlyOwner onlyStatus(WorkflowStatus.RegisteringVoters) {
        require(voter != msg.sender, "Administrator cannot be a voter !");
        require(!voters[voter].isRegistered, "Voter already registered !");
        voters[voter] = Voter(true, false, 0);
        emit VoterRegistered(voter);
    }

    // Add new proposal only if voter is whitelisted
    function registerProposal(string memory proposition) external onlyRegisteredVoter onlyStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        proposalCounter.increment();
        proposals[proposalCounter.current()] = Proposal(proposition, 0);
        emit ProposalRegistered(proposalCounter.current());
    }

    // Voters can vote
    function vote(uint proposalId) external onlyRegisteredVoter onlyStatus(WorkflowStatus.VotingSessionStarted) {
        require(proposalId >= 1 &&  proposalId <= proposalCounter.current(), "Proposal not found by the given Id !");
        require(!voters[msg.sender].hasVoted, "Already voted !");
        proposals[proposalId].voteCount += 1;
        voters[msg.sender].votedProposalId = proposalId;
        voters[msg.sender].hasVoted = true;
        emit Voted(msg.sender, proposalId);
    }

    // Counts all the votes and publish the result
    function countVotes() external onlyOwner onlyStatus(WorkflowStatus.VotingSessionEnded) {
        uint bestVote = 0;
        uint id = winningProposalId;
        for (uint i=1; i<proposalCounter.current(); i++) {
            if(proposals[i].voteCount > bestVote){
                id = i;
                bestVote = proposals[i].voteCount;
            }
        }
        winningProposalId = id;

        changeWorkflowStatus(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /*
        Set of function that change the WorkflowStatus state
    */

    function changeWorkflowStatus(WorkflowStatus previous, WorkflowStatus next) internal {
        votingStatus = next;
        emit WorkflowStatusChange(previous, next);
    }

    function startProposalRegistration() external onlyOwner onlyStatus(WorkflowStatus.RegisteringVoters) {
        changeWorkflowStatus(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function stopProposalRegistration() external onlyOwner onlyStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() external onlyOwner onlyStatus(WorkflowStatus.ProposalsRegistrationEnded) {
        changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function stopVotingSession() external onlyOwner onlyStatus(WorkflowStatus.VotingSessionStarted) {
        changeWorkflowStatus(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }
}