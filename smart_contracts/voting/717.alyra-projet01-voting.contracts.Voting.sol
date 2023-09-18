// Voting.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting contract
/// @author Grégory Seiller
/// @notice Voting contract for a small organization
contract Voting is Ownable {

    // STATES VARIABLES

    /// @notice Winning proposal Id
    /// @dev Stores the winning proposal
    uint public winningProposalID;

    /// @dev Defines a voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /// @dev Defines a proposal
    struct Proposal {
        string description;
        uint voteCount;
    }

    /// @dev Array of proposals
    Proposal[] proposals;

    /// @dev List of statuses
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @dev Status stage
    WorkflowStatus status;

    /// @dev Whitelist of voters
    mapping(address => Voter) voters;


    // EVENTS

    /// @dev Voter registration event
    /// @param voterAddress Voter's address
    event VoterRegistered(address voterAddress);

    /// @dev Worflow status change event
    /// @param previousStatus Previous status
    /// @param newStatus New status
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    /// @dev Proposal registration event
    /// @param proposalId Proposal Id
    event ProposalRegistered(uint proposalId);

    /// @dev New vote event
    /// @param voter Voter's address
    /// @param proposalId Proposal Id
    event Voted(address voter, uint proposalId);


    // MODIFIERS

    /// @dev Modifier to check if current sender is registered as a voter
    modifier isWhitelisted() {
        require(voters[msg.sender].isRegistered, "You are not in the whitelist, cannot proceed");
        _;
    }

    /// @dev Modifier to check if current status is the one expected
    /// @param _status Expected status
    modifier withStatus(uint _status) {
        require(uint(status) == _status, "Impossible during this phase");
        _;
    }


    // FUNCTIONS

    /// @notice Get voter's details based on his address
    /// @dev At any time, whitelisted voters can view a voter based on address
    /// @param _address Voter's address
    /// @return Voter's structure
    function getVoter(address _address) external view isWhitelisted returns (Voter memory) {
        return voters[_address];
    }

    /// @notice Get all proposals
    /// @dev At any time, whitelisted voters can view all listed proposals
    /// @return Array of proposals
    function getProposals() external view isWhitelisted returns(Proposal[] memory)  {
        return proposals;
    }

    /// @notice Get current status
    /// @dev At any time, whitelisted voters can view current status
    /// @return Workflow status
    function getStatus() external view isWhitelisted returns(WorkflowStatus) {
        return status;
    }

    /// @notice Owner can add a new voter
    /// @dev Owner can add a new voter to the whitelist. Current status must be RegisteringVoters. Emits VoterRegistered
    /// @param _address Voter's address
    function addVoter(address _address) external onlyOwner withStatus(0) {
        require(voters[_address].isRegistered != true, "This voter already exists");
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    /// @notice Owner starts the proposal registration phase
    /// @dev Owner starts the proposal registration phase. Current status must be RegisteringVoters. Emits WorkflowStatusChange
    function startProposalRegistration() external onlyOwner withStatus(0) {
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, status);
    }

    /// @notice Voter can add a new proposal
    /// @dev Whitelisted voters can add a new proposal. Current status must be ProposalsRegistrationStarted. Emits ProposalRegistered
    /// @param _description Proposal description
    function addProposal(string memory _description) external isWhitelisted withStatus(1) {
        require(bytes(_description).length > 0, "Cannot accept an empty proposal description");
        require(proposals.length < 100, 'Cannot accept more than 100 proposals');
        Proposal memory proposal;
        proposal.description = _description;
        proposals.push(proposal);
        emit ProposalRegistered(proposals.length-1);
    }

    /// @notice Owner ends the proposal registration phase
    /// @dev Owner ends the proposal registration phase. Current status must be ProposalsRegistrationStarted. Emits WorkflowStatusChange
    function endProposalRegistration() external onlyOwner withStatus(1) {
        require(proposals.length >= 1, "There is no submitted proposal for now, cannot end this phase");
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, status);
    }

    /// @notice Owner starts the voting phase
    /// @dev Owner starts the voting phase. Current status must be ProposalsRegistrationEnded. Emits WorkflowStatusChange
    function startVotingSession() external onlyOwner withStatus(2) {
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, status);
    }

    /// @notice Voter can vote for a proposal
    /// @dev Whitelisted voters can vote for a unique proposal. Current status must be VotingSessionStarted. Emits Voted
    /// @param _proposalId Proposal Id
    function setVote(uint _proposalId) external isWhitelisted withStatus(3) {
        require(!voters[msg.sender].hasVoted, "Already voted");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted (msg.sender, _proposalId);
    }

    /// @notice Owner ends the voting phase
    /// @dev Owner ends the voting phase. Current status must be VotingSessionStarted. Emits WorkflowStatusChange
    function endVotingSession() external onlyOwner withStatus(3) {
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, status);
    }

    /// @notice Owner tallies the final votes
    /// @dev Owner tallies the final votes. Current status must be VotingSessionEnded. Maximum 100 proposals (DoS). Emits WorkflowStatusChange
    function tallyVotes() external onlyOwner withStatus(4) {
        uint _winningProposalId;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > proposals[_winningProposalId].voteCount) {
                _winningProposalId = p;
            }
        }
        winningProposalID = _winningProposalId;
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, status);
    }
}