// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.4.0/contracts/access/Ownable.sol";

contract Voting is Ownable {
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

    uint winningProposalId;

    mapping (address => Voter) voters;

    mapping (address => uint) votes;

    Proposal[] public proposals;

    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters;

    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    modifier isWhitelisted(address _address) {
        require(voters[_address].isRegistered, "Address not whitelisted");
        _;
    }

    modifier isNotWhitelisted(address _address) {
        require(!voters[_address].isRegistered, "Address already whitelisted");
        _;
    }

    modifier hasStatus(WorkflowStatus status) {
        require(keccak256(abi.encodePacked(currentStatus)) == keccak256(abi.encodePacked(status)), "You cannot do this, invalid workflow status");
        _;
    }

    modifier canVote(address _address) {
        require(! voters[_address].hasVoted, "This voter has already voted");
        _;
    }

    function addAddressToWhitelist(address _address) public isNotWhitelisted(_address) hasStatus(WorkflowStatus.RegisteringVoters) onlyOwner {
        voters[_address].isRegistered = true;
    }

    function startProposalRegistration() public onlyOwner hasStatus(WorkflowStatus.RegisteringVoters) {
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function endProposalRegistration() public onlyOwner hasStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        emit ProposalsRegistrationEnded();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function startVoting() public onlyOwner hasStatus(WorkflowStatus.ProposalsRegistrationEnded) {
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        currentStatus = WorkflowStatus.VotingSessionStarted;
    }

    function endVoting() public onlyOwner hasStatus(WorkflowStatus.VotingSessionStarted) {
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        currentStatus = WorkflowStatus.VotingSessionEnded;
    }

    function countVotes() public onlyOwner hasStatus(WorkflowStatus.VotingSessionEnded) {
        emit VotesTallied();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        currentStatus = WorkflowStatus.VotesTallied;

        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
    }

    function submitProposal (string memory _description) public isWhitelisted(msg.sender) hasStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        proposals.push(Proposal(_description, 0));
    }

    function vote(uint _proposalId) public isWhitelisted(msg.sender) canVote(msg.sender) hasStatus(WorkflowStatus.VotingSessionStarted) {
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;         // exception if proposal not exists
        emit Voted(msg.sender, _proposalId);
    }

    function getResult() public view hasStatus(WorkflowStatus.VotesTallied) returns (uint) {
        return winningProposalId;
    }
}
