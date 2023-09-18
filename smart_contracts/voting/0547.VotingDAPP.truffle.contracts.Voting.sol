// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title A vote contract
/// @author Guillaume & Damien
/// @notice You can use this contract for only one vote
/// @dev All function calls are currently implemented without side effects

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

    struct WinnerProposal {
        uint id;
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
    WinnerProposal[] proposalsWinnerArray;

    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    constructor(){
        // Only isRegistered without emit to keep clean events list
        voters[msg.sender].isRegistered = true;
    }

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Returns the voter mapping for one address
    /// @param _addr voter address
    /// @dev Return a voter only call by a voter. 
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /// @notice Returns the proposal (description and votecount)
    /// @param _id proposal id
    /// @dev Return a proposal only call by a voter. 
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /// @notice Allow a voter to add proposal and vote
    /// @param _addr voter address
    /// @dev Allow a voter, workflowStatus check, voter, emit an event VoterRegistered with address in param. Only called by the owner 
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /// @notice Add proposal
    /// @param _desc proposal description
    /// @dev Add proposal, workflowStatus check, empty description and size of proposal array, emit an event ProposalRegistered with id  in param. Only called by voters
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        require(proposalsArray.length<10000,'Impossible to add another proposal');
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /// @notice Vote for a proposal id
    /// @param _id proposal id
    /// @dev Vote with the proposal id, workflowStatus check, already voted check, proposal id check, emit an event Voted with voter address and id in params. Only called by voters
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        //Set the winner during the vote
        if(proposalsArray[_id].voteCount>=proposalsWinnerArray[0].voteCount){
            if(proposalsArray[_id].voteCount>proposalsWinnerArray[0].voteCount){
                delete proposalsWinnerArray;
            }

            WinnerProposal memory winerProposal;
            winerProposal.id=_id;
            winerProposal.voteCount=proposalsArray[_id].voteCount;
            proposalsWinnerArray.push(winerProposal);
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice Start the proposal registration
    /// @dev Change the workflowStatus to ProposalsRegistrationStarted, workflowStatus check, add a default proposal, emit an event WorkflowStatusChange with new status status and old status. Only called by owner
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        WinnerProposal memory winerProposal;
        winerProposal.id=0;
        winerProposal.voteCount=0;
        proposalsWinnerArray.push(winerProposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice Close the proposal registration
    /// @dev Change the workflowStatus to ProposalsRegistrationEnded, workflowStatus check,emit an event WorkflowStatusChange with new status status and old status. Only called by owner
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Start the voting session
    /// @dev Change the workflowStatus to VotingSessionStarted, workflowStatus check,emit an event WorkflowStatusChange with new status status and old status. Only called by owner
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Close the voting session
    /// @dev Change the workflowStatus to VotingSessionEnded, workflowStatus check,emit an event WorkflowStatusChange with new status status and old status. Only called by owner
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice Tally the vote and close the vote
    /// @dev set the winner, return the winner id, workflowStatus check,emit an event WorkflowStatusChange with new status status and old status. Only called by owner
   function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
              
        if(proposalsWinnerArray.length>1){
            winningProposalID = 0;
        }else{
            winningProposalID = proposalsWinnerArray[0].id;
        }

        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}
