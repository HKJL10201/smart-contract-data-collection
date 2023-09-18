// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/*
* @title Voting smart contract
* @author Aymerick 
* @notice Voting smart contract to chose among several proposals
*/
contract Voting is Ownable {

    /*
    * @notice stores the winning proposal ID
    */
    uint public winningProposalID;

    /*
    * @notice defines Voter struct
    */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /*
    * @notice defines Proposal struct
    */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /*
    * @notice defines WorkflowStatus enum
    */
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /*
    * @notice stores WorkflowStatus in a variable call workflowStatus
    */
    WorkflowStatus public workflowStatus;

    /*
    * @notice stores all Proposal
    */
    Proposal[] proposalsArray;

    /*
    * @notice stores voters and these adresses
    */
    mapping (address => Voter) voters;

    /*
    * @notice defines an event when owner register a voter
    * @param voterAddress The address of the added voter
    */
    event VoterRegistered(address voterAddress); 

    /*
    * @notice defines an event when owner change Workflow status
    * @param previousStatus The previous status
    * @param newStatus The current status
    */
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    /*
    * @notice defines an event when voter register a proposal
    * @param proposalId The ID of the proposal added
    */
    event ProposalRegistered(uint proposalId);

     /*
    * @notice defines an event when voters set a vote
    * @param voter The voter address
    * @param proposalId The id of proposal voted
    */
    event Voted (address voter, uint proposalId);

    /*
    * @notice defines an event when owner tally votes
    * @param winnerId The ID of the winning proposal
    */
    event WinnerSet (uint winnerId);

    /*
    * @notice modifier to make some functions working only for voters
    */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //

    /*
    * @notice Returns a voter, works only for voters
    * @param _addr The address of a voter
    * @return voter find in voters mapping
    */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /*
    * @notice Returns a proposal, works only for voters
    * @param _id The ID of the proposal
    * @return The proposal in an object, with his description and vote count
    */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /*
    * @notice add one voter, works only for owner, emit VoterRegistered event
    * @param _addr The address of the voter
    */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /*
    * @notice add one proposal, works only for voters, emit ProposalRegistered event
    * @param _desc the description of the proposal
    */
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //
    /*
    * @notice set vote for a proposal, works only for voters, emit Voted event
    * @param _id the id of the proposal voted
    */
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

    /*
    * @notice start proposal registering, works only for owner, emit WorkflowStatusChange event
    */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /*
    * @notice end proposal registering, works only for owner, emit WorkflowStatusChange event
    */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /*
    * @notice start voting session, works only for owner, emit WorkflowStatusChange event
    */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /*
    * @notice end voting session, works only for owner, emit WorkflowStatusChange event
    */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /*
    * @notice get winner, works only for owner, emit WinnerSet and WorkflowStatusChange event
    */
    function tallyVotes() external onlyOwner {
      require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
      emit WinnerSet(winningProposalID);
      workflowStatus = WorkflowStatus.VotesTallied;
      emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}