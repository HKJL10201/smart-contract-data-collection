// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/*
 * ABOUT THIS EXERCICE :
 * - constraints : not adding any new function, not changing the workflow
 *
 * - The original contract has a secutity breach, it is vulnerable to 
 * gas limit DoS attack.This attack consist in adding a very large number of proposals
 * to have an array so big that a loop would not be abble to run it completely.
 * Its iterations would make it reach the gas limit.
 * There's 3 options to correct this breach : max number of proposal limit, pagination, evaluate the winner at each vote
 * -- having a pagination is not secure as the admin could forget to call the function,
 *  it's not a trustless solution and this makes the workflow less clear (even if he already has to manage the workflow)
 * -- having a max number of proposal is not an ethical solution because even if the limit is great
 *  it limits the potential participants
 * -- the last option is retained (evaluate the winner at each vote)
 *  it implies an extra cost (about 2500 gas) for each vote but it's counterbalanced by
 *  the suppression of the loop, a function and an event
 *  As indicated in the course we are free to do what we want with 'tallyVote'.
 *  So we remove it and the corresponding event as it saves gas.
 *  We modify the last status event name to reflect that votes are tallied at this step
 *
 * - the descritpion size of a proposal is limited to 42000 bytes as
 * between 42200 and 42900 bytes we reach the gas limit for getOneProposal()
 * without this limit, we could vote for a proposal without being able to consult its description
 *
 * - many optimizations had been made to reduce gas cost. Comparaison had been made on remix
 *  (not accessing directly storage data, decreasing the size of revert message bigger than 32 bytes, ...)
 */

/**
@title Voting contract
@author ibourn and mavy77
@notice This contract allows to register voters, register proposals, vote and tally votes
@dev The contract is Ownable
@dev Since we can't change anything in the code apart from the optimization and the flaw, 
the equality case will be treated as follows: the first proposal having reached this number of votes is chosen as the winner.
@inheritdoc Ownable
 */
 import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    ///@notice the id of the propsals array that has the most votes
    uint public winningProposalID;
    
    /**
    @notice Voter struct
    @param isRegistered, true if the voter is registered
    @param hasVoted, true if the voter has voted
    @param votedProposalId, the id of the proposal the voter voted for
    */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**
    @notice Proposal struct
    @param description, Proposal description, a non empty string
    @param voteCount, Proposal vote count
    */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /**
    @notice Workflow steps represented by an enum
    @dev Removing tallyVotes() to correct the breach, we remove the last status 'VotesTallied'
    and so we renamed VotingSessionEnded in VotingEndedAndTallied
     */
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingEndedAndTallied
    }

    ///@notice the current status of the vote represented by the WorkflowStatus enum
    WorkflowStatus public workflowStatus;
    ///@notice array of proposals whose id corresponds to the chronological order of addition
    Proposal[] proposalsArray;
    ///@notice map of Voter struct corresponding to the voter addresses
    mapping (address => Voter) voters;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // :::::::::::::::::::::::::: GETTERS :::::::::::::::::::::::::::::: //

    /**
    @notice get the Voter struct corresponding to the address
    @param _addr, the address of the voter
    @return Voter struct
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /**
    @notice get the Proposal struct corresponding to the id
    @param _id, the id of the proposal
    @return Proposal struct
     */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }
 
    // ::::::::::::::::::::::: REGISTRATION ::::::::::::::::::::::::::: //

    /*
     * @todo : increase test as function is modified
     * @comment : 163 gas saved (execution cost)
     */
    /**
    @notice register a voter
    @dev the function can only be called by the owner
    @dev the function can only be called when the workflow status is RegisteringVoters
    @dev the voter must not be already registered
    @dev the voter is registered by setting the isRegistered boolean to true
    @dev emit a VoterRegistered event
    @param _addr, the address of the voter
     */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open');
        Voter storage currentVoter = voters[_addr];
        require(currentVoter.isRegistered != true, 'Already registered');
    
        currentVoter.isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::::::::::::::: PROPOSAL ::::::::::::::::::::::::::::: //
    
    /**
    @notice register a proposal
    @dev the function can only be called by a registered voter
    @dev the function can only be called when the workflow status is ProposalsRegistrationStarted
    @dev the proposal description must not be empty
    @dev the proposal description must not be too long (< 42000 bytes)
    @dev the proposal is registered by adding it to the proposalsArray, so it's chronological id is the last index of the array
    @dev emit a ProposalRegistered event
    @param _desc, the description of the proposal
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Proposal can t be empty'); // facultatif
        require(bytes(_desc).length < 42000, "Description too long");

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::::::::::::::::: VOTE ::::::::::::::::::::::::::::::: //

    /**
    @notice register a vote
    @dev the function can only be called by a registered voter
    @dev the function can only be called when the workflow status is VotingSessionStarted
    @dev the voter must not have already voted
    @dev the proposal id must correspond to a registered proposal
    @dev the voter is registered by setting the hasVoted boolean to true
    @dev the voter is registered by setting the votedProposalId to the proposal id
    @dev the vote count of the proposal is incremented
    @dev if the proposal vote count is greater than the current winning proposal vote count, the winning proposal id is set to the proposal id  
    @dev emit a Voted event
    @param _id, the id of the proposal
     */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session not open');
        Voter storage currentVoter = voters[msg.sender];
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        Proposal[] storage proposals = proposalsArray;
        require(_id < proposals.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        currentVoter.votedProposalId = _id;
        currentVoter.hasVoted = true;

        bool isWinningId;
        unchecked { isWinningId = ++proposals[_id].voteCount > proposals[winningProposalID].voteCount; }
        if (isWinningId) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // :::::::::::::::::::::::::: STATUS :::::::::::::::::::::::::::::: //

    /**
    @notice change the workflow status to ProposalsRegistrationStarted
    @dev the function can only be called by the owner
    @dev the function can only be called when the workflow status is RegisteringVoters
     */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voter registration not open');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
    @notice change the workflow status to ProposalsRegistrationEnded
    @dev the function can only be called by the owner
    @dev the function can only be called when the workflow status is ProposalsRegistrationStarted
     */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposal registration not open');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
    @notice change the workflow status to VotingSessionStarted
    @dev the function can only be called by the owner
    @dev the function can only be called when the workflow status is ProposalsRegistrationEnded
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Proposal registration not closed');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
    @notice change the workflow status to VotingEndedAndTallied
    @dev the function can only be called by the owner
    @dev the function can only be called when the workflow status is VotingSessionStarted
     */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session has not started');
        workflowStatus = WorkflowStatus.VotingEndedAndTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingEndedAndTallied);
    }
}