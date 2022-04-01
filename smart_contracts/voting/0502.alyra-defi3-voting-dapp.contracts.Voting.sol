// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A voting system contract.
 *
 * @author Dé Yi Banh
 *
 * @dev A voting system.
 */
contract Voting is Ownable {
    uint private highestVoteCount;
    WorkflowStatus private workflowStatus;
    Proposal[] private proposals;
    mapping (address => Voter) private voters;
    mapping (uint => uint[]) private proposalsIdsVoteCounts;
    mapping (uint => Proposal[]) private proposalsVoteCounts;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
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

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voterAddress, uint proposalId);

    /**
     * @dev Constructor.
     */
    constructor() Ownable() {
        addVoter(msg.sender);
    }

    /**
     * @dev Check if the sender is registered in the voters list.
     */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You are not registered as voter.");
        _;
    }

    /**
     * @dev Compare two string and return a boolean.
     *
     * @param _str1 The first string.
     * @param _str2 The second string.
     *
     * @return bool Returns false if there is a difference, otherwise returns true.
     */
    function strcmp(string memory _str1, string memory _str2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((_str1))) == keccak256(abi.encodePacked((_str2))));
    }

    /**
     * @dev Get the highest vote counted.
     *
     * @return uint The highest vote counted.
     */
    function getHighestVoteCount() external view returns (uint) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "The workflow status cannot allowed you to see the highest vote count.");

        return highestVoteCount;
    }

    /**
     * @dev Get the workflow status.
     *
     * @return Workflowstatus The workflowStatus.
     */
    function getWorkflowstatus() external view returns (WorkflowStatus) {
        return workflowStatus;
    }

    /**
     * @dev Add a proposal with a description.
     *
     * @param _description The description of the proposal.
     */
    function addProposal(string memory _description) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "The workflow status cannot allowed you to request proposals.");
        require(!strcmp(_description, ""), "Please enter a valid description.");

        Proposal memory proposal;
        proposal.description = _description;
        proposals.push(proposal);

        emit ProposalRegistered(proposals.length - 1);
    }

    /**
     * @dev Get all proposal.
     *
     * @return Proposal[] The proposal list.
     */
    function getProposals() external view onlyVoters returns (Proposal[] memory)  {
        return proposals;
    }

    /**
     * @dev Get a proposal information with an the proposal id.
     *
     * @param _proposalId The proposal id.
     *
     * @return Proposal The proposal information.
     */
    function getProposal(uint _proposalId) external view onlyVoters returns (Proposal memory) {
        require(_proposalId < proposals.length, "Proposal not found. Please enter a valid id.");

        return proposals[_proposalId];
    }

    /**
     * @dev Add a voter address into the voters list.
     *
     * @param _voterAddress The voter address.
     */
    function addVoter(address _voterAddress) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "The workflow status cannot allowed you to add voters.");
        require(!voters[_voterAddress].isRegistered, "The voter is already registered.");

        voters[_voterAddress].isRegistered = true;

        emit VoterRegistered(_voterAddress);
    }

    /**
     * @dev Remove a voter address from the voters list.
     *
     * @param _voterAddress The voter address.
     */
    function removeVoter(address _voterAddress) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "The workflow status cannot allowed you to remove voters.");
        require(voters[_voterAddress].isRegistered, "The voter is already not registered.");

        voters[_voterAddress].isRegistered = false;

        emit VoterRegistered(_voterAddress);
    }

    /**
     * @dev Get a voter information.
     *
     * @param _voterAddress The voter address.
     *
     * @return Voter The voter.
     */
    function getVoter(address _voterAddress) external onlyVoters view returns (Voter memory) {
        return voters[_voterAddress];
    }

    /**
     * @dev Start to register proposals.
     */
    function startRegisteringProposals() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "The workflow status not allowed you to start registering proposals.");

        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @dev Stop registering proposals.
     */
    function stopRegisteringProposals() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "The workflow status not allowed you to stop registering proposals."
        );

        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;

        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @dev Start the voting session.
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "The workflow status not allowed you to start the voting session.");

        workflowStatus = WorkflowStatus.VotingSessionStarted;

        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev Vote to a proposal.
     *
     * @param _proposalId The proposal id.
     */
    function vote(uint _proposalId) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "The workflow status not allowed you to vote.");
        require(_proposalId < proposals.length, "Proposal not found. Please enter a valid id.");
        require(!voters[msg.sender].hasVoted, "You have already voted.");

        voters[msg.sender].votedProposalId = _proposalId;
        voters[msg.sender].hasVoted = true;
        proposals[_proposalId].voteCount++;

        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @dev Stop the voting session.
     */
    function stopVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "The workflow status not allowed you to stop the voting session.");
        
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Tally all votes. Sort into voteCounts mapping all the proposalIds by vote counted then store the hightest vote count.
     */
    function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "The workflow status not allowed you to tally votes.");

        for (uint proposalId = 0; proposalId < proposals.length; proposalId++) {
            Proposal memory proposal = proposals[proposalId];
            proposalsIdsVoteCounts[proposal.voteCount].push(proposalId);
            proposalsVoteCounts[proposal.voteCount].push(proposal);

            if (highestVoteCount < proposal.voteCount) {
                highestVoteCount = proposal.voteCount;
            }
        }

        workflowStatus = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /**
     * @dev Get a list of winning proposal ids.
     *
     * @return uint[] A list of winning proposal ids.
     */
    function getWinningProposalIds() external view returns (uint[] memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "The workflow status cannot allowed you to see the winners proposal ids.");

        return proposalsIdsVoteCounts[highestVoteCount];
    }

    /**
     * @dev Get a list of winning proposal.
     *
     * @return Proposal[] A list of winning proposals.
     */
    function getWinners() external view returns (Proposal[] memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "The workflow status cannot allowed you to see the winners proposals.");

        return proposalsVoteCounts[highestVoteCount];
    }
}
