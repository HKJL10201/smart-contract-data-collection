// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title A voting system
/// @author Cyril Castagnet & Pierre-Frédéric Murillo
/// @notice Each allowed voter can set a proposal, then vote for a proposal
/// @dev Use the nbrVotersMax variable to set the number of allowed voters
contract Voting is Ownable {

    uint public winningProposalID;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        bool hasSubmitted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;

    uint public nbrVoters;
    uint public nbrVotersMax = 5;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    /// @notice restrict function access to allowed voters
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    /// @notice get a single voter details
    /// @param _addr the voter address
    /// @return Voter: the voter structure 
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }

    /// @notice get a single proposal details
    /// @param _id the proposal id (uint)
    /// @return Proposal: the proposal structure 
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /// @notice add an address to the allowed voters list 
    /// @param _addr the voter address
    /// @dev restricted to the contract's owner
    /// @dev emits an event VoterRegistered
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(nbrVoters < nbrVotersMax, 'Max voters number has been reached');
        require(voters[_addr].isRegistered != true, 'Already registered');    
        voters[_addr].isRegistered = true;
        nbrVoters++;
        emit VoterRegistered(_addr);
    }
 
    /// @notice register a proposal, restricted to allowed voters
    /// @param _desc the proposal description
    /// @dev emits an event ProposalRegistered
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(!voters[msg.sender].hasSubmitted, 'Proposal already submitted');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        voters[msg.sender].hasSubmitted = true;
        emit ProposalRegistered(proposalsArray.length-1);
    }

    /// @notice register a user vote, restricted to allowed voters
    /// @param _id the proposal id (uint)
    /// @dev emits an event Voted
    function setVote(uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id <= proposalsArray.length, 'Proposal not found');
        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;
        emit Voted(msg.sender, _id);
    }

    /// @notice update worflow status, restricted to contract owner
    /// @dev emits an event WorkflowStatusChange
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice update worflow status, restricted to contract owner
    /// @dev emits an event WorkflowStatusChange
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice update worflow status, restricted to contract owner
    /// @dev emits an event WorkflowStatusChange
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice update worflow status, restricted to contract owner
    /// @dev emits an event WorkflowStatusChange
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice update worflow status, then define winning proposal, restricted to contract owner
    /// @dev emits an event WorkflowStatusChange
    function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
        uint _winningProposalId;
        for (uint256 p = 0; p < proposalsArray.length; p++) {
            if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
                _winningProposalId = p;
            }
        }
        winningProposalID = _winningProposalId;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}