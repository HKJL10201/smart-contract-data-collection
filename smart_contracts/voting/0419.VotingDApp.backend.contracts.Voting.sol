// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A voting system smart contract
/// @author Noam Mansouri, Yannick Tison
/// @notice this contract should not be used for production but only  as a learning support


contract Voting is Ownable {

    /// @notice store the winning propoal ID
    uint public winningProposalID;

    /**
    @notice Voter struct
    @param isRegistered true if the voter is registered
    @param hasVoted true if the voter has voted
    @param votedProposalId the proposal Id the voter voted for
    */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**
    @notice Proposal struct
    @param description Proposal description
    @param voteCount Proposal vote count
    */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /// @notice workflow status list for the voting process
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @notice  store the current workflowStatus
    WorkflowStatus public workflowStatus;

    /// @notice store all proposals as an array of Proposal struct
    Proposal[] proposalsArray;

    /// @notice store all registered voters in a mapping : key = voter address , value  = Voter structure
    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
    
    /// @dev Check if user is a registered voter
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter"); 
        _;
    }
    
    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //
    /// @notice Get the corresponding Voter (structure Voter) for specified address
    /// @param _addr Voter's address
    /// @return a Voter object corresponding to given address

    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }


    /// @notice Get the corresponding proposal (structure Proposal) for a given proposal index
    /// @param _id Proposal id 
    /// @return Proposal Proposal object corresponding to given id
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 
    /// @notice Register a Voter
    /// @param _addr address of the voter to register
    /// @dev emit a VoterRegistered event
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 
    /// @notice Add a proposal 
    /// @param _desc The proposal description
    /// @dev emit a ProposalRegistered event

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
    /// @notice Vote for the proposal with given id
    /// @param _id Id of the proposal to vote for
    /// @dev to fix the tallyVote DOS breach if too many proposals are submitted, we evaluate and maintain the winning proposal on each setVote request
    /// @dev emit a Voted event

    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        // if _id proposal became the proposal with current max vote, then assign winningProposalID
        // if equality, the last winning proposal remain the same
        // this code could avoid the loop in tally function
        if (proposalsArray[_id].voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //
    /// @notice Change workflow status to ProposalsRegistrationStarted
    /// @dev emit a WorkflowStatusChange event

    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice Change workflow status to ProposalsRegistrationEnded
    /// @dev emit a WorkflowStatusChange event

    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Change workflow status to VotingSessionStarted
    /// @dev emit a WorkflowStatusChange event
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Change workflow status to VotingSessionEnded
    /// @dev emit a WorkflowStatusChange event
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }


    /// @notice Tally vote function for the owner
    /// @dev this function is now useless and we could delete it and only keep the endVotingSession() to tally the vote
    /// @dev emit a WorkflowStatusChange event
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}