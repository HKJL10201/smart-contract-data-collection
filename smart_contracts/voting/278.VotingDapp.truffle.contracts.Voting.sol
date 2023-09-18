// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title A voting contract
/// @author Frelot.P
/// @notice You can use this contract for only one vote 
/// @inheritdoc Ownable

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    /// @notice Winning proposal id
    uint public winningProposalID;
    
    /// @notice Voter struct
    /// @param isRegistered Voter is registered
    /// @param hasVoted Voter has voted
    /// @param votedProposalId Voter voted proposal id
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /// @notice Proposal struct
    /// @param description Proposal description
    /// @param voteCount Proposal vote count
    struct Proposal {
        string description;
        uint voteCount;
    }

    /// @notice Workflow status enum
    /// @param RegisteringVoters Registering voters
    /// @param ProposalsRegistrationStarted Proposals registration started
    /// @param ProposalsRegistrationEnded Proposals registration ended
    /// @param VotingSessionStarted Voting session started
    /// @param VotingSessionEnded Voting session ended
    /// @param VotesTallied Votes tallied
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @notice Workflow status
    WorkflowStatus public workflowStatus;
    /// @notice Proposals array
    Proposal[] proposalsArray;
    /// @notice Voters mapping
    mapping (address => Voter) voters;

    /// @notice Voter registered event
    /// @param voterAddress Voter address
    event VoterRegistered(address voterAddress); 
    /// @notice Workflow status change event
    /// @param previousStatus Previous workflow status
    /// @param newStatus New workflow status
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    /// @notice Proposal registered event
    /// @param proposalId Proposal id
    event ProposalRegistered(uint proposalId);
    /// @notice Voted event
    /// @param voter Voter address
    event Voted (address voter, uint proposalId);
    

    /// @notice Only voters modifier
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //
    /// @notice Get voter's information by his address, only voters
    /// @param _addr Voter address
    /// @return Voter Voter
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /// @notice Get one proposal
    /// @param _id Proposal id
    /// @return Proposal Proposal
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 
    /// @notice Add a voter in 'voters', only owner, emit VoterRegistered. Should be called only once for each voter and when workflowStatus is RegisteringVoters
    /// @param _addr Voter address
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 
    /// @notice Add proposal of 'msg.sender' in 'proposals', only voters, emit ProposalRegistered. should be called only when workflowStatus is  ProposalsRegistrationStarted no empty description allowed
    /// @param _desc Proposal description
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //
    /// @notice Set the vote of 'msg.sender', only voters, emit Voted. should be called only when workflowStatus is VotingSessionStarted should be called only once for each voter and for a registered proposal
    /// @param _id Proposal id
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        if (proposalsArray[_id].voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //
    /// @notice Start registering voters, only owner, emit WorkflowStatusChange. should be called only when workflowStatus is RegisteringVoters
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice End registering voters, only owner, emit WorkflowStatusChange. should be called only when workflowStatus is ProposalsRegistrationStarted
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Start voting session, only owner, emit WorkflowStatusChange. should be called only when workflowStatus is ProposalsRegistrationEnded
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /** @notice End voting session, only owner, emit WorkflowStatusChange. 
    should be called only when workflowStatus is VotingSessionStarted */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice Tally votes, only owner, emit WorkflowStatusChange. 
    /// stores winningProposalID should be called only when workflowStatus is VotingSessionEnded
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
              
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}
