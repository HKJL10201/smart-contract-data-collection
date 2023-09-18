// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @dev Contract which provides a simple voting mechanism
 * A vote follows this workflow :
 * - Registering Voters :
 *   the administrator is allowed to register the list of voters using the addVoter function.
 *   Once done, the administrator can call startProposalsRegistering to go to the next step.
 * - ProposalsRegistrationStarted :
 *   the registered voters can submit some voting options (they can submit any number of voting
 *   proposal) using addProposal function.
 *   Note that the administrator is not allowed to submit voting options unless he added himself
 *   as a registered voter.
 *   Registered voters can get info from a proposal using getOneProposal.
 *   Once all proposals have been submited, the administrator shall call endProposalsRegistering
 *   to go to next step.
 * - ProposalsRegistrationEnded :
 *   Voters can't send proposals anymore.
 *   Administrator can go to next state anytime he wants by using startVotingSession function.
 * - VotingSessionStarted :
 *   the registered voters are now allowed to submit their voting choice using setVote function.
 *   Each voter can only submit one voting choice and will not be allowed to change his vote.
 *   Once done, the administrator shall call endVotingSession to go to the next step.
 * - VotingSessionEnded :
 *   voting is not possible anymore and the result is now final.
 */

contract Voting is Ownable {
  uint public winningProposalID;

  struct Voter {
    uint votedProposalId;
    bool isRegistered;
    bool hasVoted;
  }

  struct Proposal {
    string description;
    uint voteCount;
  }

  enum WorkflowStatus {
    RegisteringVoters,
    ProposalsRegistrationStarted,
    ProposalsRegistrationEnded,
    VotingSessionStarted,
    VotingSessionEnded
  }

  uint latestProposalId;
  WorkflowStatus public workflowStatus;

  mapping(uint => Proposal) proposalsMapping;
  mapping(address => Voter) voters;

  /**
   * @dev Emitted when `voterAddress` is registered as a voter.
   */
  event VoterRegistered(address voterAddress);

  /**
   * @dev Emitted when workflow status changes from `previousStatus` to `newStatus`.
   */
  event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

  /**
   * @dev Emitted when a new proposal with identifier `proposalId` is registered by a voter.
   */
  event ProposalRegistered(uint proposalId);

  /**
   * @dev Emitted when `voter` voted for proposal with identifier `proposalId`.
   */
  event Voted(address voter, uint proposalId);

  /**
   * @dev Throws if called by any account that is not a voter.
   */
  modifier onlyVoters() {
    require(voters[msg.sender].isRegistered, "You're not a voter");
    _;
  }

  // on peut faire un modifier pour les états

  // ::::::::::::: GETTERS ::::::::::::: //

  /**
   * @dev     Allow voters to get vote info from any voter
   * @param   _addr  Address of the voter
   * @return  Voter
   */
  function getVoter(address _addr) external view onlyVoters returns (Voter memory) {
    return voters[_addr];
  }

  /**
   * @dev     Allow voters to get info about a proposal
   * @param   _id  Proposal ID
   * @return  Proposal
   */
  function getOneProposal(uint _id) external view onlyVoters returns (Proposal memory) {
    require(_id < latestProposalId, 'Proposal not found');
    return proposalsMapping[_id];
  }

  // ::::::::::::: REGISTRATION ::::::::::::: //

  /**
   * @dev     Register a new voter (owner only)
   * @param   _addr  address of the voter to register
   */
  function addVoter(address _addr) external onlyOwner {
    require(
      workflowStatus == WorkflowStatus.RegisteringVoters,
      'Voters registration is not open yet'
    );
    require(voters[_addr].isRegistered != true, 'Already registered');

    voters[_addr].isRegistered = true;
    emit VoterRegistered(_addr);
  }

  // ::::::::::::: PROPOSAL ::::::::::::: //

  /**
   * @dev     Add a vote option (voters only)
   * @param   _desc  Textual description of the proposal
   */
  function addProposal(string calldata _desc) external onlyVoters {
    require(
      workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
      'Proposals are not allowed yet'
    );
    require(
      keccak256(abi.encode(_desc)) != keccak256(abi.encode('')),
      'Vous ne pouvez pas ne rien proposer'
    ); // facultatif
    // voir que desc est different des autres

    Proposal memory proposal;
    proposal.description = _desc;
    proposalsMapping[latestProposalId] = proposal;
    unchecked {
      ++latestProposalId;
    }
    emit ProposalRegistered(latestProposalId - 1);
  }

  // ::::::::::::: VOTE ::::::::::::: //

  /**
   * @dev     Allow registered voters to vote for their favorite voting option
   * @param   _id  ID of the voted proposal
   */
  function setVote(uint _id) external onlyVoters {
    require(
      workflowStatus == WorkflowStatus.VotingSessionStarted,
      'Voting session havent started yet'
    );
    require(voters[msg.sender].hasVoted != true, 'You have already voted');
    require(_id < latestProposalId, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

    voters[msg.sender].votedProposalId = _id;
    voters[msg.sender].hasVoted = true;
    unchecked {
      ++proposalsMapping[_id].voteCount;
    }
    // To prevent DOS gas limit attack, we update the winning id after each new vote
    if (proposalsMapping[_id].voteCount > proposalsMapping[winningProposalID].voteCount) {
      winningProposalID = _id;
    }
    emit Voted(msg.sender, _id);
  }

  // ::::::::::::: STATE ::::::::::::: //

  /**
   * @dev End voters registration step and start proposals registration step
   */
  function startProposalsRegistering() external onlyOwner {
    require(
      workflowStatus == WorkflowStatus.RegisteringVoters,
      'Registering proposals cant be started now'
    );
    workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

    Proposal memory proposal;
    proposal.description = 'GENESIS';
    proposalsMapping[latestProposalId++] = proposal;

    emit WorkflowStatusChange(
      WorkflowStatus.RegisteringVoters,
      WorkflowStatus.ProposalsRegistrationStarted
    );
  }

  /**
   * @dev End voters proposals registering step
   */
  function endProposalsRegistering() external onlyOwner {
    require(
      workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
      'Registering proposals havent started yet'
    );
    workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
    emit WorkflowStatusChange(
      WorkflowStatus.ProposalsRegistrationStarted,
      WorkflowStatus.ProposalsRegistrationEnded
    );
  }

  /**
   * @dev Start voting session
   */
  function startVotingSession() external onlyOwner {
    require(
      workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
      'Registering proposals phase is not finished'
    );
    workflowStatus = WorkflowStatus.VotingSessionStarted;
    emit WorkflowStatusChange(
      WorkflowStatus.ProposalsRegistrationEnded,
      WorkflowStatus.VotingSessionStarted
    );
  }

  /**
   * @dev End voting session
   */
  function endVotingSession() external onlyOwner {
    require(
      workflowStatus == WorkflowStatus.VotingSessionStarted,
      'Voting session havent started yet'
    );
    workflowStatus = WorkflowStatus.VotingSessionEnded;
    emit WorkflowStatusChange(
      WorkflowStatus.VotingSessionStarted,
      WorkflowStatus.VotingSessionEnded
    );
  }

  fallback() external {}
}
