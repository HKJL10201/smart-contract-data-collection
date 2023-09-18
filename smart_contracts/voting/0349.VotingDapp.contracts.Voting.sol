// SPDX-License-Identifier: MIT

pragma solidity 0.8.13; 
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting System
/// @author Alyra

/// @dev using Ownable contract from openzeppelin library for the modifier onlyOwner
contract Voting is Ownable {

    /// @return winningProposalID index of the winning proposal
    uint public winningProposalID;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
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
    /// @return workflowStatus current workflow status
    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;

    event VoterRegistered(address _voterAddress); 
    event WorkflowStatusChange(WorkflowStatus _previousStatus, WorkflowStatus _newStatus);
    event ProposalRegistered(uint _proposalId);
    event Voted (address _voter, uint _proposalId);

    /// @notice limit access to registered voters
    /// @dev check if the sender address is registered in voters mapping
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    /// @notice register owner as voter when contract is deployed
    /** @dev when contract is deployed
        add Voter struct to voters mapping set isRegistered to true
        emit event VoterRegistered with registered voter address*/  
    constructor()  {
          voters[msg.sender].isRegistered = true;
          emit VoterRegistered(msg.sender);
    }

    /// ::::::::::::: GETTERS ::::::::::::: ///
    /// @notice get details of a voter
    /// @dev retrieves voter properties from voters mapping
    /// @param _addr requested voter address
    /// @return voters[_addr] voter data from voters mapping
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /// @notice get details of a proposal
    /// @dev retrieves Proposal struct properties from proposals array
    /// @param _id requested proposal index
    /// @return proposalsArray[_id] proposal data from proposals array
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /// ::::::::::::: REGISTRATION ::::::::::::: /// 
    
    /// @notice register a voter on whitelist
    /** @dev add Voter struct to voters mapping set isRegistered to true
        emit event VoterRegistered with registered voter address*/ 
    /// @param _addr voter to add address 
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 
    /// ::::::::::::: PROPOSAL ::::::::::::: /// 

    /// @notice register proposal
    /// @dev add Proposal struct to proposals array
    /// @param _desc short description of the proposal to add
    /// @dev emit ProposalRegistered event with proposal index
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); /// facultatif
        require(proposalsArray.length < 50,'The maximum number of proposals has been reached');/** to avoid DOS attacks
        regarding iteration in tallyVotes()*/
        
        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    /// ::::::::::::: VOTE ::::::::::::: ///

    /// @notice vote for a proposal
    /// @param _id index of the proposal to vote for
    /** @dev set voter property hasVoted to true, add 1 to proposal property voteCount
        emit event Voted with address of the sender and Id of the voted proposal*/
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); /// pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    /// ::::::::::::: STATE ::::::::::::: ///

    /// @notice start proposals registration stage
    /** @dev set WorkflowStatus to ProposalsRegistrationStarted
        emit event WorkflowStatusChange with previous WorkflowStatus and current WorkflowStatus */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice end proposals registration stage
    /** @dev set WorkflowStatus to ProposalsRegistrationEnded
        emit event WorkflowStatusChange with previous WorkflowStatus and current WorkflowStatus */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice start voting session stage
    /** @dev set WorkflowStatus to VotingSessionStarted
        emit event WorkflowStatusChange with previous WorkflowStatus and current WorkflowStatus */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice end voting session stage
    /** @dev set WorkflowStatus to VotingSessionEnded
        emit event WorkflowStatusChange with previous WorkflowStatus and current WorkflowStatus */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice tally votes
    /** @dev iterate on proposalsArray to find teh highest voteCount
        set _winningProposalID to highest VoteCount index proposal
        emit event WorkflowStatusChange with previous WorkflowStatus and current WorkflowStatus */
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