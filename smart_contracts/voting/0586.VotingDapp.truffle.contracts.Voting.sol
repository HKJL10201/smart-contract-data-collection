// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @author Cyril Castagnet
 * @notice A simple voting contract with 4 main steps (registring voters, proposal registring, voting session and votes tallying)
 * @dev A simple voting contract
 */
contract Voting is Ownable {

    /// State variable to record the winning proposal
    uint public winningProposalID;
    
    /**
    * @dev A complex type that represent a single voter with three params (bool isRegistered, bool hasVoted, uint votedProposalId)
    */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**
    * @dev A complex type that represent a single proposal with two params (string description, uint voteCount)
    */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /**
    * @dev A variable with predefined values that represents the status of the workflow
    */
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @dev A state variable of type WorkflowStatus that stores the workflow status
    WorkflowStatus public workflowStatus;
    /// @dev A dynamic size array storing Proposal structs
    Proposal[] proposalsArray;
    /// @dev A state variable that stores a Voter struct for each address
    mapping (address => Voter) public voters;

    /// @dev An event that registers the voter address
    event VoterRegistered(address voterAddress);
    /// @dev An event that registers the current workflow status and the next when the status changes
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    /// @dev An event that registers the proposal id
    event ProposalRegistered(uint proposalId);
    /// @dev An event that registers the voter address and the proposal id he voted for
    event Voted (address voter, uint proposalId);
    
    /// A modifier of type control that checks that voter is registred in the voters array
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //
    /**
     * @dev Get a voter informations
     * @param _addr The address of the voter 
     * @return A matching address voter struct  
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
     /**
     * @dev Get a voter informations
     * @param _id The address of the voter 
     * @return A matching address voter struct  
     */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /**
     * @dev Add a voter to the voter mapping
     * @dev Only the owner of the contract can use this function
     * @dev The workflowstatus must be at registring voters step
     * @dev The voter must not be registred
     * @dev winning proposal is calculated each time a proposal is selected
     * @param _addr The address of the voter 
     */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 
    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /**
     * @dev Add a proposal to the proposal array
     * @dev Only voters regitred can use this function
     * @dev The workflowstatus must be at proposal registering started step
     * @dev The proposal can't be an ampty string
     * @param _desc The proposal 
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'No empty proposal');
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

     /**
     * @dev Set a proposal for the msg.sender
     * @dev Only voters registred can use this function
     * @dev The workflowstatus must be at voting session started step
     * @dev The msg.sender must not have already voted
     * @dev The proposal must have been registred
     * @param _id The id of the proposal 
     */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found');

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        if (proposalsArray[_id].voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /**
     * @dev Start proposal registring step
     * @dev Only the owner of the contract can use this function
     * @dev The workflowStatus must be at registring voter step
     * @dev The proposal array is initiated with a zero index proposition called GENESIS
     */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @dev End proposal registring step
     * @dev Only the owner of the contract can use this function
     * @dev The workflowStatus must be at proposal registration started step
     */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

     /**
     * @dev Start voting session step
     * @dev Only the owner of the contract can use this function
     * @dev The workflowStatus must be at proposal registration ended step
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev End voting session step
     * @dev Only the owner of the contract can use this function
     * @dev The workflowStatus must be at voting session started step
     */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Tally votes
     * @dev Only the owner of the contract can use this function
     * @dev The workflowStatus must be at voting session ended step
     * @dev The workflow changes to votes tallied
     */
    function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");

       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}