// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title Proposals voting system
/// @author smart contract programmer
/// @notice You can use this contract for setting up a proposals voting system
contract Voting is Ownable {
    /// Index of the winning proposal
    uint256 public winningProposalID;

    /// Voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    /// An object Proposal with a description and a number of votes
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    /// Status of the workflow
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// Current status of the workflow
    WorkflowStatus public workflowStatus;

    /// List of proposals
    Proposal[] public proposalsArray;

    /// Voters in the whitelist
    mapping(address => Voter) voters;

    /// @notice This event is emitted when a vote is registered.
    /// @param voterAddress Voter's address
    event VoterRegistered(address voterAddress);

    /// @notice This event is emitted when a voter is registered.
    /// @param previousStatus Status before update
    /// @param newStatus Status after update
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    /// @notice This event is emitted when a proposal is registered.
    /// @param proposalId Index of the proposal in the table
    event ProposalRegistered(uint256 proposalId);

    /// @notice This event is emitted when a voter has voted for a proposal
    /// @param voter Voter's address
    /// @param proposalId Index of the proposal in the table
    event Voted(address voter, uint256 proposalId);

    /// @notice This modifier checks that the voter is registered to perform the action
    /// @dev sg.sender is the caller
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Return a voter by a specific address
    /// @param _addr caller's address
    /// @return Voter object
    function getVoter(address _addr)
        external
        view
        onlyVoters
        returns (Voter memory)
    {
        return voters[_addr];
    }

    /// @notice Return a proposal by id
    /// @param _id Index of the proposal in the table
    /// @return Proposal made by a voter
    function getOneProposal(uint256 _id)
        external
        view
        onlyVoters
        returns (Proposal memory)
    {
        return proposalsArray[_id];
    }

    /// @notice Return the count of proposals
    /// @return uint256 Count of proposals
    function getProposalsArrayCount()
        external
        view
        onlyVoters
        returns (uint256)
    {
        return proposalsArray.length;
    }

    // ::::::::::::: REGISTRATION ::::::::::::: //

    /// @notice Add a voter in the whitelist
    /// @param _addr voter's address to add in the whitelist
    /// @dev Function can only be called by the deployer of the contract
    function addVoter(address _addr) external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Voters registration is not open yet"
        );
        /// Check the presence of the voter is the whitelist
        require(voters[_addr].isRegistered != true, "Already registered");

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: PROPOSAL ::::::::::::: //

    /// @notice Add a proposal
    /// @param _desc Description of the proposal
    /// @dev Function can only be called by a registered voter
    function addProposal(string calldata _desc) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposals are not allowed yet"
        );
        /// Description must not be empty
        require(
            keccak256(abi.encode(_desc)) != keccak256(abi.encode("")),
            "Vous ne pouvez pas ne rien proposer"
        );

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length - 1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /// @notice Vote for a proposal
    /// @param _id Index of the proposal in the table
    /// @dev Function can only be called by a registered voter
    function setVote(uint256 _id) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );

        /// The voter must not have voted
        require(voters[msg.sender].hasVoted != true, "You have already voted");
        /// Check the existence of the proposal in the table
        require(_id < proposalsArray.length, "Proposal not found");

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        /// @Dev patch To evict a DoS Gas Limit attack in tallyVotes - Identify the winning proposal
        if (
            proposalsArray[_id].voteCount >
            proposalsArray[winningProposalID].voteCount
        ) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice The contract owner starts the proposals registering session
    /// @dev Function can only be called by the deployer of the contract
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

    /// @notice The contract owner stops the proposals registering session
    /// @dev Function can only be called by the deployer of the contract
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

    /// @notice The contract owner starts the voting session
    /// @dev Function can only be called by the deployer of the contract
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

    /// @notice The contract owner stops  the voting session
    /// @dev Function can only be called by the deployer of the contract
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

    /// @notice Count the votes - Finalise the votes
    function tallyVotes() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "Current status is not voting session ended"
        );
        /// @Dev The commented code is done for preventing a DOS gaz limit attack.
        /// The count of the votes is done in setVote function. Function can only be called by the deployer of the contract

        /*
        uint256 _winningProposalId;
        for (uint256 p = 0; p < proposalsArray.length; p++) {
            if (
                proposalsArray[p].voteCount >
                proposalsArray[_winningProposalId].voteCount
            ) {
                _winningProposalId = p;
            }
        }
        winningProposalID = _winningProposalId;*/

        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }
}
