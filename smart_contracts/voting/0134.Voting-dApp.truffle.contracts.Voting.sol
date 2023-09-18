// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol).
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @author Julien Chevallier
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Voting is Ownable {

    /**
     * @notice Returns the winning proposal.
     * @dev By default this will be set to 0.
     *
     * Visibility is set to public to let anyone get the winning proposal ID.
     */
    uint public winningProposalId;

    /**
     * @notice Represents the structure of a voter.
     *
     * @param isRegistered      : Boolean for Voter registration = true or false.
     * @param hasVoted          : Boolean for Voter has voted = true or false.
     * @param votedProposalId   : Number corresponding to the Proposal Id.
     */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**
     * @notice Represents the structure of a proposal.
     *
     * @param description       : String for the description of the Proposal.
     * @param voteCount         : Number of vote(s) for the proposal.
     */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /**
     * @notice Status of the different voting session.
     */
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /**
     * @notice Returns the status of the workflow at any time.
     *
     * @dev By default this will be set to 0 (RegisteringVoters).
     * Public visibility is set to let anyone read the current status of the workflow.
     */
    WorkflowStatus public workflowStatus;

    /**
     * @notice Returns the state of the workflow Status any time during the voting session.
     */
    Proposal[] public proposals;

    /**
     * @notice Mapping of voters by addresses.
     */
    mapping(address => Voter) public voters;

    /**
     * @notice Event triggered when voters are registered.
     */
    event VoterRegistered(address voterAddress);

    /**
     * @notice Event triggered when the Workflow Status is modified.
     */
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    /**
     * @notice Event triggered when Proposals are registered.
     */    
    event ProposalRegistered(address voter, uint proposalId);

    /**
     * @notice Event triggered when voting is closed.
     */    
    event Voted (address voter, uint proposalId);

    /**
     * @notice Checks if a voter is currently registered.
     * @dev Reverts if not called by a whitelisted voter's address.
     */
    modifier onlyVoter() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    /**
     * @notice Gets the registered voter structure by address.
     * @dev Only registered voters can call the function.
     *
     * @param _address             : address of the voter.
     *
     * @return returns the voter's structure (bool: isRegistered, bool: hasVoted, uint256: votedProposalId).
     */
    function getVoter(address _address) external onlyVoter view returns (Voter memory) {
        return voters[_address];
    }

    /**
     * @notice Gets the proposal ID.
     * @dev Only registered voters can call the function.
     *
     * @param _id             : ID of the proposal.
     *
     * @return returns the proposal's structure (string: description ,uint256: voteCount).
     */
    function getOneProposal(uint _id) external onlyVoter view returns (Proposal memory) {
        return proposals[_id];
    }

    /**
     * @notice Owner starts the proposal registration phase
     * @dev Current status must be RegisteringVoters.
     * 
     * Emits a {WorkflowStatusChange} event.
     */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @notice Owner ends the proposal registration phase.
     * @dev Current status must be RegisteringVoters.
     * 
     * Emits a {WorkflowStatusChange} event.
     */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @notice Owner starts the voting session.
     * @dev Current status must be ProposalsRegistrationEnded.
     * 
     * Emits a {WorkflowStatusChange} event.
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

        /**
     * @notice Owner ends the voting session.
     * @dev Current status must be VotingSessionStarted.
     * 
     * Emits a {WorkflowStatusChange} event.
     */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @notice Adds a voter to the whitelist.
     * @dev Only the owner can call the function.
     *
     * @param _address            : address of the voter.
     *
     * Emits a {VoterRegistered} event.
     *
     * Requirements:
     *
     * - `WorkflowStatus` must be at the RegisteringVoters state.
     * - `voter` cannot be already registered.
     */
    function addVoter(address _address) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_address].isRegistered != true, 'Already registered');
    
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    /**
     * @notice Adds a proposal (maximum 50 proposals).
     * @dev Only registered voters can add a proposal.
     *
     * @param _description             : Proposal's description.
     *
     * Emits a {ProposalRegistered} event.
     *
     * Requirements:
     *
     * - `WorkflowStatus` must be at the ProposalsRegistrationStarted state.
     * - `Description` can't be empty.
     * - `Max length` = 50 proposals.
     */
    function addProposal(string memory _description) external onlyVoter {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_description)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer');
        require(proposals.length <= 50, 'Max proposals amount reached (x50)');

        Proposal memory proposal;
        proposal.description = _description;
        proposals.push(Proposal(_description, 0));

        emit ProposalRegistered(msg.sender, proposals.length-1);
    }

    /**
     * @notice Voter can vote for a proposal.
     * @dev Only registered voters can vote.
     * Voters can vote only once.
     *
     * @param _proposalId           : id of the proposal.
     *
     * Emits a {Voted} event.
     *
     * Requirements:
     *
     * - `WorkflowStatus` must be at the VotingSessionStarted state.
     * - `voter` cannot have already voted.
     */
    function vote(uint _proposalId) external onlyVoter {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');

        voters[msg.sender].votedProposalId = _proposalId;
        voters[msg.sender].hasVoted = true;
        proposals[_proposalId].voteCount++;

        if (proposals[_proposalId].voteCount > proposals[winningProposalId].voteCount) {
            winningProposalId = _proposalId;
        }

        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @notice Owner tallies all the votes
     * @dev Current status must be VotingSessionEnded
     *
     * Emits a {WorkflowStatusChange} event.
     *
     * Requirements:
     *
     * - `WorkflowStatus` must be at the VotingSessionEnded state.
    * - `Max length` = 50 proposals.
     */
    function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
        require(proposals.length <= 50, 'Max proposals amount reached (x50)'); // security

        uint _winningProposalId;

        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > proposals[_winningProposalId].voteCount) {
                _winningProposalId = p;
            }
        }
        winningProposalId = _winningProposalId;
       
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
    
    /**
     * @notice Gets the winning proposal Id.
     * @dev Only owner can call this function.
     *
     */
    function getWinningProposalId() public onlyOwner view returns (uint256 proposalId, string memory description, uint256 voteCount) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Current status is not votes tallied");
        return (winningProposalId, proposals[winningProposalId].description, proposals[winningProposalId].voteCount);   
    }
}