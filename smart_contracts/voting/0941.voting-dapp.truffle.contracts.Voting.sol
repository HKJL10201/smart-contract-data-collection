// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title An Voting contract example
/// @author Multi Author !
/// @notice This contract is a simple test for a voting system 
/// @dev Inherits the OpenZepplin Ownable implentation
contract Voting is Ownable {

    /// @notice Returns the winning proposal 
    uint public winningProposalID;
    
    /// @notice Voter structure : to know if he is registered / if he has already voted / the proposal number 
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /// @notice Proposal structure with description of proposal and the number of counts 
    struct Proposal {
        string description;
        uint voteCount;
    }

    /// @notice Workflow enum (the steps of the voting)
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @notice current selected workflow 
    WorkflowStatus public workflowStatus;

    /// @notice the list (array) with all proposals 
    Proposal[] proposalsArray;

    /// @notice the mapping of all voters
    mapping (address => Voter) voters;

    /// @notice the list of events 
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
    /// @notice modifier to check if an account is registered and is allowed to vote
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Return the Voter structure
    /// @dev Could only be called by a voter
    /// @param _addr the account address to check 
    /// @return Voter struct
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /// @notice Retrieve a proposal structure
    /// @dev Could only be called by a voter
    /// @param _id the id of a proposal
    /// @return the Proposal
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /// @notice Add a voter and emit a "VoterRegistered" event
    /// @dev Could only be called by the owner 
    /// @param _addr the voter address 
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /// @notice Add a proposal and emit a "ProposalRegistered" event
    /// @dev Could only be called by a voters. 
    /// @param _desc proposal description
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif

        // limit the maximum number of proposal (see below) 
        // require(proposalsArray.length < 20,"Sorry we have a maximum proposal limit");

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /// @notice Vote : select a proposal and emit a "Voted" event
    /// @dev Could only be called by a voters  
    /// @param _id proposal id
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice Start proposal registering and emit a "WorkflowStatusChange" event
    /// @dev Could only be called by the owner 
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        /// Probably this was a test/debug ? I would delete this (make the proposalArray correct !) or at least comments the purpose of this 
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice End proposal registering and emit a "WorkflowStatusChange" event
    /// @dev Could only be called by the owner  
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Start a voting session and emit a "WorkflowStatusChange" event
    /// @dev Could only be called by the owner
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice End a voting session and emit a "WorkflowStatusChange" event
    /// @dev Could only be called by the owner
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice Tally the votes and emit a "WorkflowStatusChange" event
    /// @dev Could only be called by the owner
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       uint _winningProposalId;

       // To avoid too many gas fees ... I would limit the number of proposal 
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