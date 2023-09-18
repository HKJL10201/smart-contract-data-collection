// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @author mlazzje
 * @notice Voting smart contract - Alyra Rinkeby 2022 Project #1
 */
contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    struct Proposal {
        string description;
        uint256 voteCount;
    }
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Constant
    // @dev added only for my girlfriend to test and understand the workflow :)
    string[6] private workflowStatusString = [
        "RegisteringVoters",
        "ProposalsRegistrationStarted",
        "ProposalsRegistrationEnded",
        "VotingSessionStarted",
        "VotingSessionEnded",
        "VotesTallied"
    ];

    // Variables
    Proposal[] public proposals;
    WorkflowStatus public status;
    mapping(address => Voter) public voters;
    address[] private votersArray; // @dev to reset voters mapping
    uint256 private winningProposalId;

    // Events
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    constructor() {
        status = WorkflowStatus.RegisteringVoters;
    }

    // Modifiers
    // @dev allow function to run if status passed in parameter is equal to the current contract status
    modifier checkStatus(WorkflowStatus _status) {
        require(
            status == _status,
            string.concat(
                "Wrong stage! Contract is currently ",
                workflowStatusString[uint256(status)],
                ". This function can only run when this smart contract status = ",
                workflowStatusString[uint256(_status)]
            )
        );
        _;
    }

    // @dev allow function to run if it's not too early
    modifier checkTooEarlyStatus(WorkflowStatus _status) {
        require(
            uint256(status) >= uint256(_status),
            string.concat(
                "Too early! Contract is currently ",
                workflowStatusString[uint256(status)],
                ". This function can only run when this smart contract status >= ",
                workflowStatusString[uint256(_status)]
            )
        );
        _;
    }

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You are not a voter!");
        _;
    }

    // @dev get currentStatus for information
    function getStatus() public view returns (string memory) {
        return workflowStatusString[uint256(status)];
    }

    // @dev go to next stage by following WorkflowStatus, protected at the end of the session
    function nextStage() public onlyOwner {
        require(
            status != WorkflowStatus.VotesTallied,
            "Votes tallied, you can get winning proposal or get vote or reset!"
        );
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus(uint256(status) + 1);
        emit WorkflowStatusChange(oldStatus, status);
    }

    // @dev to restart another voting session when the previous session is over
    function reset() public onlyOwner checkStatus(WorkflowStatus.VotesTallied) {
        winningProposalId = 0; // Remove winningProposalId
        for (uint256 i = 0; i < votersArray.length; i++) {
            delete voters[votersArray[i]];
        }
        delete proposals;
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.RegisteringVoters;
        emit WorkflowStatusChange(oldStatus, status);
    }

    function addVoter(address _voterAddress)
        public
        onlyOwner
        checkStatus(WorkflowStatus.RegisteringVoters)
    {
        require(!voters[_voterAddress].isRegistered, "Voter already added!");
        voters[_voterAddress].isRegistered = true;
        votersArray.push(_voterAddress);
        emit VoterRegistered(_voterAddress);
    }

    function addProposal(string memory _proposalDescription)
        public
        checkStatus(WorkflowStatus.ProposalsRegistrationStarted)
        onlyVoters
    {
        proposals.push(Proposal(_proposalDescription, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    function vote(uint256 _proposalId)
        public
        checkStatus(WorkflowStatus.VotingSessionStarted)
        onlyVoters
    {
        require(!voters[msg.sender].hasVoted, "You already voted!");
        proposals[_proposalId].voteCount++; // Should revert automatically if this proposalId doesn't exist
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
        // @dev TODO Automatic next stage when last voter voted
    }

    function getVote(address _voterAddress)
        public
        view
        checkTooEarlyStatus(WorkflowStatus.VotingSessionStarted)
        onlyVoters
        returns (string memory)
    {
        if (voters[_voterAddress].hasVoted) {
            return proposals[voters[_voterAddress].votedProposalId].description;
        } else {
            return "Voter didn't vote yet!";
        }
    }

    function nominateWinningProposal()
        public
        onlyOwner
        checkStatus(WorkflowStatus.VotingSessionEnded)
    {
        uint256 winningVoteCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                // doesn't manage draw
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        nextStage();
    }

    function getWinningProposalId()
        public
        view
        checkStatus(WorkflowStatus.VotesTallied)
        returns (uint256)
    {
        return winningProposalId;
    }

    function getWinningProposal()
        public
        view
        checkStatus(WorkflowStatus.VotesTallied)
        returns (string memory)
    {
        return proposals[winningProposalId].description;
    }
}

