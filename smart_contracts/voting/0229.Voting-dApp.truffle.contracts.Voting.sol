// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting management contract
/// @notice This contract allows users to create proposals and vote for them. 
///         The owner should handle the voting contract status changes.
/// @dev The proposal ids for voters should start from 1. 
///      For the convenience a genesis proposal is created upon vote start.
/// @author Mickaël Blondeau
contract Voting is Ownable {

    /// @notice the id of the winning proposal
    uint public winningProposalID;
    
    /// @notice Description of a voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /// @notice Description of a proposal
    struct Proposal {
        string description;
        uint voteCount;
    }

    /// @notice Enumeration of the differents status of the workflow 
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @notice The status of the worflow
    WorkflowStatus public workflowStatus;
    /// @notice Array of the proposals
    Proposal[] proposalsArray;
    /// @notice Map of an address to a voter
    mapping (address => Voter) voters;

    /// @notice Event triggered when a voter is registered
    /// @param voterAddress the voter's address
    event VoterRegistered(address voterAddress); 

    /// @notice Event triggered when the workflow changes
    /// @param previousStatus the previous status of the workflow
    /// @param newStatus the previous status of the workflow
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    /// @notice Event triggered when a proposal is registered
    /// @param proposalId the id of the proposal
    event ProposalRegistered(uint proposalId);
    
    /// @notice Event triggered when a vote is added
    /// @param voter the voter's address
    /// @param proposalId the id of the proposal
    event Voted (address voter, uint proposalId);
    
    /// @notice check if the sender is a voter
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Get the voter
    /// @dev use the modifier onlyVoters
    /// @param _addr the voter's address
    /// @return Returns the voter
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }

    /// @notice Get one proposal
    /// @dev use the modifier onlyVoters
    /// @param _id the id of the proposal
    /// @return Returns the proposal
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /// @notice Add a voter
    /// @dev use the modifier onlyOwner
    /// @param _addr the voter's address
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /// @notice Add a proposal
    /// @dev use the modifier onlyVoters
    /// @param _desc the description of the proposal
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        proposalsArray.push(Proposal(_desc, 0));
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //
    
    /// @notice Set a vote
    /// @dev use the modifier onlyVoters and calculate the winner gradually (fix : ddos gas limit attack)
    /// @param _id the id of the proposal
    function setVote(uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        Voter storage voter = voters[msg.sender];
        voter.votedProposalId = _id;
        voter.hasVoted = true;
        Proposal storage proposal = proposalsArray[_id];
        ++proposal.voteCount;

        if (proposal.voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice Workflow changed : start the registering of the proposals
    /// @dev use the modifier onlyOwner. A "genesis" proposal is created there. 
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        proposalsArray.push(Proposal("GENESIS", 0));
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice Workflow changed : end of the registering of the proposals
    /// @dev use the modifier onlyOwner
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Workflow changed : start the voting session
    /// @dev use the modifier onlyOwner
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Workflow changed : end of the voting session
    /// @dev use the modifier onlyOwner
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice tally the votes and defines the winning proposal
    /// @dev use the modifier onlyOwner
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}