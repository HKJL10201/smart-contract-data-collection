// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
// Import of OpenZeppelin Contracts Ownable
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @dev Implements voting process along with vote delegation
 * with the help of OpenZeppelin Ownable
 * and the management of the voting process by an andministrator who is the owner of the contract
 * @author  https://github.com/Gregcrn
 */
contract Voting is Ownable {
    /**
     * @notice Returns the winning proposal taking all previous votes into account
     * @dev This declares a new complex type which will
     * be used for variables later.
     * It will represent a the winning proposal.
     * Visibility is set to public to let everyone access it.
     * By default it is set to 0.
     */
    uint256 public winningProposalID;
    /**
     * @notice The struct of a Voter
     * @dev This declares a new complex type which will be used for variables later.
     * It represents a single voter.
     * @params isRegistered is a boolean to know if the voter is registered
     * @params hasVoted is a boolean to know if the voter has already voted
     * @params votedProposalId is the proposal ID of the proposal on which the voter has voted
     */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    /**
     * @notice The struct of a Proposal
     * @dev This declares a new complex type which will be used for variables later.
     * It represents a single proposal.
     * @params description is the description of the proposal
     * @params voteCount is the number of votes for this proposal
     */
    struct Proposal {
        string description;
        uint256 voteCount;
    }
    /**
     * @notice Enum of the different states of the voting process
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the different states of the voting process.
     */
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    /**
     * @notice The current state of the voting process
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the current state of the voting process.
     * By default it is set to RegisteringVoters.
     * Visibility is set to public to let everyone access it.
     */
    WorkflowStatus public workflowStatus;
    /**
     * @notice Return the array of all the proposals
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the array of all the proposals.
     * Visibility is set to public to let everyone access it.
     */
    Proposal[] public proposalsArray;
    /**
     * @notice Return the mapping of all the voters with their address as key
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the mapping of all the voters with their address as key.
     */
    mapping(address => Voter) voters;
    /**
     * @notice The event emitted when a voter is registered
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the event emitted when a voter is registered.
     * @param voterAddress is the address of the voter
     */
    event VoterRegistered(address voterAddress);
    /**
     * @notice Get when the workflow status has changed with previous and new status
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the event emitted when the workflow status has changed.
     * @param previousStatus is the previous status of the workflow
     * @param newStatus is the new status of the workflow
     */
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    /**
     * @notice triggered when a proposal is added
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the event emitted when a proposal is added with proposalID.
     * @param proposalId is the ID of the proposal
     */
    event ProposalRegistered(uint256 proposalId);
    /**
     * @notice triggered when a voter has voted
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the event emitted when a voter has voted.
     * @param voter is the address of the voter who has voted
     * @param proposalId is the ID of the proposal on which the voter has voted
     */
    event Voted(address voter, uint256 proposalId);
    /**
     * @notice Check if the voter is registered
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the modifier to check if the voter is registered.
     * Revert if the voter is not registered.
     */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //

    /**
     * @notice Get a voter with his address
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to get a voter with his address.
     * @param _addr is the address of the voter
     * Return the struct of the voter like {bool: isRegistered, bool: hasVoted, uint256: votedProposalId}
     */
    function getVoter(address _addr)
        external
        view
        onlyVoters
        returns (Voter memory)
    {
        return voters[_addr];
    }

    /**
     * @notice Get a proposal with his ID
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to get a proposal with his ID.
     * @param _id is the ID of the proposal
     * Return the struct of the proposal like {string: description, uint256: voteCount}
     */
    function getOneProposal(uint256 _id)
        external
        view
        onlyVoters
        returns (Proposal memory)
    {
        return proposalsArray[_id];
    }

    // ::::::::::::: REGISTRATION ::::::::::::: //
    /**
     * @notice Register a voter
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to register a voter.
     * Emit the event VoterRegistered with the address of the voter.
     * Revert if the voter is already registered.
     * Revert if the workflow status is not RegisteringVoters.
     * @param _addr is the address of the voter
     */
    function addVoter(address _addr) external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Voters registration is not open yet"
        );
        require(voters[_addr].isRegistered != true, "Already registered");

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: PROPOSAL ::::::::::::: //
    /**
     * @notice Add a proposals by voter
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to start the registration of the proposals.
     * Only voter can call this function through the modifier onlyVoters.
     * Emit the event WorkflowStatusChange with the previous and new status.
     * Emit the event ProposalRegistered with the array length of the proposals.
     * Revert if the workflow status is not ProposalsRegistrationStarted.
     * @param _desc is the description of the proposal
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposals are not allowed yet"
        );
        require(
            keccak256(abi.encode(_desc)) != keccak256(abi.encode("")),
            "Vous ne pouvez pas ne rien proposer"
        ); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length - 1);
    }

    // ::::::::::::: VOTE ::::::::::::: //
    /**
     * @notice Vote for a proposal
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to vote for a proposal.
     * Only voter can call this function through the modifier onlyVoters.
     * Emit the event Voted with the address of the voter and the ID of the proposal.
     * Revert if the workflow status is not VotingSessionStarted.
     * Revert if the voter has already voted.
     * @param _id is the ID of the proposal
     */
    function setVote(uint256 _id) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        require(voters[msg.sender].hasVoted != true, "You have already voted");
        require(_id < proposalsArray.length, "Proposal not found"); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        if (
            proposalsArray[_id].voteCount >
            proposalsArray[winningProposalID].voteCount
        ) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //
    /**
     * @notice Start the registration of the voters
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to start the registration of the voters.
     * Only owner can call this function through the modifier onlyOwner.
     * Emit the event WorkflowStatusChange with the previous and new status.
     * Revert if the workflow status is not RegisteringVoters.
     */
    function startProposalsRegistering() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Registering proposals cant be started now"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);

        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    /**
     * @notice End the proposals registration
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to start the voting session.
     * Only owner can call this function through the modifier onlyOwner.
     * Emit the event WorkflowStatusChange with the previous and new status.
     * Revert if the workflow status is not ProposalsRegistrationStarted.
     */
    function endProposalsRegistering() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Registering proposals havent started yet"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    /**
     * @notice Start the voting session
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to start the voting session.
     * Only owner can call this function through the modifier onlyOwner.
     * Emit the event WorkflowStatusChange with the previous and new status.
     * Revert if the workflow status is not ProposalsRegistrationEnded.
     */
    function startVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Registering proposals phase is not finished"
        );
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    /**
     * @notice End the voting session
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to end the voting session.
     * Only owner can call this function through the modifier onlyOwner.
     * Emit the event WorkflowStatusChange with the previous and new status.
     * Revert if the workflow status is not VotingSessionStarted.
     */
    function endVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    /**
     * @notice End the voting session
     * @dev This declares a new complex type which will be used for variables later.
     * It represents the function to end the voting session.
     * Only owner can call this function through the modifier onlyOwner.
     * Emit the event WorkflowStatusChange with the previous and new status.
     * Revert if the workflow status is not VotingSessionEnded.
     */
    function tallyVotes() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "Current status is not voting session ended"
        );

        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }
}
