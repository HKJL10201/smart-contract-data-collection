// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting system contract
/// @author JWMatheo
/// @notice You can use this contract for DAO purpose.
/// @dev Voting contract

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


    /**
    * @dev modifier that check if the sender is registered as a voter.
    */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    /**
    * @notice Check if you are registered.
    * @dev Check if an address is registered as a voter. 
    * @param _addr The address to check.
    * @return Voter structure of the entered address.
    */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /**
    * @notice Check one proposal.
    * @dev Check any proposal by their id.
    * @param _id The id of the proposal in proposal array.
    * @return Proposal structure of the entered id.
    */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /**
    * @dev Add the address '_addr' as a voter.
    *
    * Emits a {VoterRegistered} event with `voterAddress` set to '_addr' address.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'RegisteringVoters'.
    * - '_addr' is not an address already registered.
    * @param _addr The address to add as a voter.
    */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    /**
    * @notice Add a proposal.
    * @dev Voter add a proposal to proposalsArray.
    *
    * Emits a {ProposalRegistered} event with `proposalId` set to his index in proposal array.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'ProposalsRegistrationStarted'.
    * - '_desc' is not empty.
    * @param _desc The description of the proposal.
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

    /**
    * @notice Voter vote for a proposal.
    * @dev Voter vote for a proposal in proposalsArray.
    *
    * Emits a {Voted} event with `voter` set to the caller address and with 'proposalId' set to '_id'.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'VotingSessionStarted'.
    * - 'hasVoted' is not true.
    * - '_id' of the proposal exist.
    * @param _id The id of the proposal.
    */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id <= proposalsArray.length, 'Proposal not found');

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    } 

    /**
    * @dev Set 'workflowStatus' to 'ProposalsRegistrationStarted'.
    *
    * Emits a {WorkflowStatusChange} event with `previousStatus` set to 'RegisteringVoters' and with 'newStatus' set to 'ProposalsRegistrationStarted'.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'RegisteringVoters'.
    */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
    * @dev Set 'workflowStatus' to 'ProposalsRegistrationEnded'.
    *
    * Emits a {WorkflowStatusChange} event with `previousStatus` set to 'ProposalsRegistrationStarted' and with 'newStatus' set to 'ProposalsRegistrationEnded'.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'ProposalsRegistrationStarted'.
    */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
    * @dev Set 'workflowStatus' to 'VotingSessionStarted'.
    *
    * Emits a {WorkflowStatusChange} event with `previousStatus` set to 'ProposalsRegistrationEnded' and with 'newStatus' set to 'VotingSessionStarted'.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'ProposalsRegistrationEnded'.
    */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
    * @dev Set 'workflowStatus' to 'VotingSessionEnded'.
    *
    * Emits a {WorkflowStatusChange} event with `previousStatus` set to 'VotingSessionStarted' and with 'newStatus' set to 'VotingSessionEnded'.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'VotingSessionStarted'.
    */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
    * @dev Tally all votes, the proposal with the hightest voteCount win. 
    *
    * Emits a {WorkflowStatusChange} event with `VotingSessionEnded` set to 'VotingSessionStarted' and with 'newStatus' set to 'VotesTallied'.
    *
    * Requirements:
    *
    * - `workflowStatus` is set to 'VotingSessionEnded'.
    */
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
    
    /**
     * @dev Get the winning Proposal Information
     * @return description of the winning proposal
     * @return voteCount : number of votes for the winning proposal
     */
    function getWinningProposal() external view returns(string memory description, uint256 voteCount){
        require(workflowStatus == WorkflowStatus.VotesTallied, "Vote Result not already reveal"); 
        return (
            proposalsArray[winningProposalID].description,
            proposalsArray[winningProposalID].voteCount
        );
    }
}