// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/*
 @title Voting
 @dev Smart contract for conducting a voting process using blockchain technology
 @author Alyra. Updated by Guilhain Averlant & Pierre Olivier Mauget
 @notice This contract allows voters to register, submit proposals, and vote on proposals
 @notice The voting process has multiple stages that are controlled by the contract owner
 @notice Voters can only vote once and can only vote on proposals that have been registered
 @notice The winning proposal is the one with the highest number of votes
*/

contract Voting is Ownable {

    uint public winningProposalID;
    uint proposalID;

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
        VotingSessionEnded
    }

    WorkflowStatus public workflowStatus;
    // Proposal[] proposalsArray;
    mapping (uint => Proposal) proposalsMapping;
    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //

    /*
    @notice Returns the voter information for a given address.
    @param _addr The address of the voter.
    @return The voter's information including registration status, vote status, and voted proposal ID.
    */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }

    /*
    @notice Returns a single proposal from the proposalsMapping based on its ID.
    @param _id uint ID of the proposal to retrieve.
    @return Proposal memory The proposal object containing all of its details.
    */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        require(_id <= proposalID, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        return proposalsMapping[_id];
    }


    // ::::::::::::: REGISTRATION ::::::::::::: //

    /*
    @notice Registers a new voter by adding their address to the list of voters.
    @dev Requirements:
    @dev     - The workflow status must be "RegisteringVoters".
    @dev     - The voter must not already be registered.
    @param _addr The address of the voter to register.
    @emit a VoterRegistered event.
    */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }


    // ::::::::::::: PROPOSAL ::::::::::::: //

    /*
    @notice Adds a new proposal to the proposals array.
    @dev  Requirements:
    @dev     - The workflow status must be set to ProposalsRegistrationStarted.
    @dev     - The proposal description cannot be an empty string.
    @dev     - Only registered voters can add a proposal.
    @param _desc A string representing the proposal's description.
    @emit a ProposalRegistered event.
    */
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalID += 1;
        proposalsMapping[proposalID] = proposal;
        emit ProposalRegistered(proposalID);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /*
    @notice Allows a registered voter to vote for a proposal with a given ID.
    @dev Requirements:
    @dev     - Voting session must have started.
    @dev     - The voter must not have voted before.
    @dev     - The proposal ID must exist.
    @dev To avoid Gas Limit Exceeded error, we compute the winning proposal ID in the same function
    @param _id The ID of the proposal to vote for.
    @emit a Voted event.
    */
    function setVote(uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id <= proposalID, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsMapping[_id].voteCount++;

        // we compute the winning proposal
        if (proposalsMapping[_id].voteCount > proposalsMapping[winningProposalID].voteCount) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //
    
    /*
    @notice Allows the owner to start the proposals registration process
    @dev This function can only be called when the workflow status is set to RegisteringVoters
    @dev The function initializes the workflow status to ProposalsRegistrationStarted
    @dev The function also creates a GENESIS proposal with id 0
    @emit a WorkflowStatusChange event with the old and new workflow status
    */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsMapping[0] = proposal;
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /*
    @notice End the proposals registration period
    @dev Only the owner can call this function
    @dev The workflow status must be "ProposalsRegistrationStarted"
    @dev Once the function is called, the workflow status will be changed to "ProposalsRegistrationEnded"
    @emit a "WorkflowStatusChange" event with the previous status "ProposalsRegistrationStarted" and the new status "ProposalsRegistrationEnded"
    */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /*
     * @notice Start the voting session, only the contract owner can call this function
     * @dev The workflow status must be `ProposalsRegistrationEnded` to start the voting session
     * @emit a `WorkflowStatusChange` event with `ProposalsRegistrationEnded` and `VotingSessionStarted` as parameters
    */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /*
    @notice End the voting session and update the workflow status to `VotingSessionEnded`.
    @dev This function can only be called by the contract owner.
    @dev Requires that the workflow status is currently `VotingSessionStarted`.
    @emit a `WorkflowStatusChange` event with the previous and current workflow status.
    */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

}
