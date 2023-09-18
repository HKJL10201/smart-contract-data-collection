// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Voting Contract
 *
 * Voting contract extends Ownable
 *
 */
contract Voting is Ownable {

    uint public winningProposalID;
    string public description;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint proposalRegisteredCount; // limit to 3
        // Si un voter peut ajouter autant de proposition qu'il veut, il peut alors faire grossir le tableau au point de ne plus pouvoir appeller la function "tallyvotes"
        uint votedProposalId;
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

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    /**
     * @dev The owner can set the description (the question) of the Voting Session
     *
     * After ProposalRegistration started, it cannot be changed anymore
     *
     */
    function setDescription(string calldata _description) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Cannot change description anymore');
        description = _description;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /**
     * @dev Return a Voter - only accessible by Voters
     *
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }

    /**
     * @dev Return a Proposal - only accessible by Voters
     *
     */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }


    // ::::::::::::: REGISTRATION ::::::::::::: //

    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }


    // ::::::::::::: PROPOSAL ::::::::::::: //

    /**
     * @dev Add a new proposal
     *
     * Requirements:
     *
     * - `_desc` must not be empty
     *
     * Security :
     * - Each voter can add no more than 3 proposal
     * - This is to prevent having too much proposals in the array and not be able to use TallyVote anymore.
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres
        require(voters[msg.sender].proposalRegisteredCount < 3, 'Vous ne pouvez pas faire + de 3 propositions');

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        voters[msg.sender].proposalRegisteredCount++;
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

     /**
     * @dev Vote for a proposal - sender must be a voter
     *
     * Requirements:
     *
     * - `_id` must not be less than proposalArray.length
     *
     */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //


    /**
     * @dev Start proposal Registration
     *
     * - Sender must be owner
     * - workflow must be at RegisteringVoters
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
     * @dev End proposal Registration
     *
     * - Sender must be owner
     * - workflow must be at ProposalsRegistrationStarted
     */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @dev Start Voting Session
     *
     * - Sender must be owner
     * - workflow must be at ProposalsRegistrationEnded
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev End Voting Session
     *
     * - Sender must be owner
     * - workflow must be at VotingSessionStarted
     */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Call this metho to tally vote
     *
     * - Sender must be owner
     * - workflow must be at VotingSessionEnded
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
}