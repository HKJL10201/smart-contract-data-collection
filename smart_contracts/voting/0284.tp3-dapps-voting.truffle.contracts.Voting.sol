// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title A voting system
/// @author charles CHD
/// @notice You can use this contract for template voting system or used for personnal usage
/// @dev All function calls are currently implemented without side effects
/// @custom:this is a exercice contract

contract Voting is Ownable {

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

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    

    /// @notice check if user this function is a voter
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }



    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //


    /// @notice return a voter storage in mapping 
    /// @param _addr it's a address a voter who can return
    /// @return voter 
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    

    /// @notice return one prosposal storage array 
    /// @dev The Alexandr N. Tetearing algorithm could increase precision
    /// @param _id the id number for find a proposal
    /// @return Age in years, rounded up for partial years
    function getOneProposal(uint256 _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }


    /// @notice function allows to return all proposal in array
    /// @dev it could be optimal call for create list proposal with description
    /// @return {proposalsArray} 
    function getProposals() external onlyVoters view returns (Proposal[] memory) {
        return proposalsArray;
    }
 
    // ::::::::::::: REGISTRATION ::::::::::::: // 


    /// @notice function add a voter in mapping(whitelisters-like) by Owner (onlyOwner)
    /// @dev it's verifie who can register just one time
    /// @param _addr it's address person who want register in mapping
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 
    /// @notice function add a proposal in array by Voter who is registers (onlyVoter)
    /// @dev this function can execute by only workflowstatus (ProposalsRegistrationStarted) and verifie a doublon proposal 
    /// @param _desc  it's string description for proposal
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
    /// @notice function set a vote in mapping voter , represent a proposal id  choice by voter
    /// @dev this function can execute by status (VotingSessionStarted) and verifie if voter have already voted
    /// @dev it was proposed to count the votes here to allow better management of gas costs thus avoiding a dos gas limit
    /// @param _id  id proposal selected by voter
    /// @param Voted  event who log adress voter and id proposal selected by voter
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        if(proposalsArray[_id].voteCount > proposalsArray[winningProposalID].voteCount ){
            winningProposalID = _id;

        }
        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice function set a workflow proposal registering, can be used by Owner
    /// @dev this function open a voter write a proposal in array proposal, this array init one proposal "genesis"
    /// @param workflowStatusChange  event allows log previous workflow(RegisteringVoters) and next workflow (ProposalsRegistrationStarted)
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice function set a workflow end proposal session , can be used by Owner
    /// @dev this function close a proposal session, a voter must waiting admin to open next session
    /// @param workflowStatusChange  event allows log previous workflow(ProposalsRegistrationStarted) and next workflow(ProposalsRegistrationEnded)
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }


    /// @notice function set a workflow start a voting session , can be used by Owner
    /// @dev this function allows a voter acces to function "set a vote"
    /// @param workflowStatusChange  event allows log previous workflow(ProposalsRegistrationEnded) and next workflow(VotingSessionStarted)
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }


    /// @notice function set a workflow end  voting session , can be used by Owner
    /// @dev this function close vote session,a voter must waiting admin to open next session"
    /// @param workflowStatusChange  event allows log previous workflow(VotingSessionStarted) and next workflow(VotingSessionEnded)
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice function set a workflow tally voes , can be used by Owner
    /// @dev this function close a session vote"
    /// @param workflowStatusChange  event allows log previous workflow(VotingSessionEnded) and next workflow(VotesTallied)
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}
