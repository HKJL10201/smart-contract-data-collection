// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

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

    mapping(address => Voter) public voters;
    address[] public voterAddresses;
    Proposal[] public proposals;
    WorkflowStatus public status;
    uint public winningProposalId;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    constructor() {
        status = WorkflowStatus.RegisteringVoters;
    }

    modifier inStatus(WorkflowStatus _status) {
        require(status == _status, "L'etat du workflow n'autorise pas cette fonction.");
        _;
    }

    modifier isRegisteredVoter(address _voter) {
        require(voters[_voter].isRegistered, "L'electeur n'est pas inscrit.");
        _;
    }

    modifier hasNotVoted(address _voter) {
        require(!voters[_voter].hasVoted, "L'electeur a deja vote.");
        _;
    }

    function registerVoter(address _voter) public onlyOwner inStatus(WorkflowStatus.RegisteringVoters) {
        require(!voters[_voter].isRegistered, "L'electeur est deja inscrit.");
        voters[_voter] = Voter(true, false, 0);
        voterAddresses.push(_voter);
        emit VoterRegistered(_voter);
    }

    function startProposalsRegistration() public onlyOwner inStatus(WorkflowStatus.RegisteringVoters) {
        WorkflowStatus previousStatus = status;
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(previousStatus, status);
    }

    function registerProposal(string calldata _description) public isRegisteredVoter(msg.sender) inStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        Proposal memory newProposal = Proposal(_description, 0);
        proposals.push(newProposal);
        emit ProposalRegistered(proposals.length - 1);
    }

    function endProposalsRegistration() public onlyOwner inStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        WorkflowStatus previousStatus = status;
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(previousStatus, status);
    }

    function startVotingSession() public onlyOwner inStatus(WorkflowStatus.ProposalsRegistrationEnded) {
        WorkflowStatus previousStatus = status;
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(previousStatus, status);
    }

    function vote(uint _proposalId) public isRegisteredVoter(msg.sender) hasNotVoted(msg.sender) inStatus(WorkflowStatus.VotingSessionStarted) {
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }

    function endVotingSession() public onlyOwner inStatus(WorkflowStatus.VotingSessionStarted) {
        WorkflowStatus previousStatus = status;
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(previousStatus, status);
    }

    function tallyVotes() public onlyOwner inStatus(WorkflowStatus.VotingSessionEnded) {
        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }
        winningProposalId = winningProposalIndex;
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, status);
    }

    function getWinner() public view inStatus(WorkflowStatus.VotesTallied) returns (string memory) {
        return proposals[winningProposalId].description;
    }

    function resetVote() external onlyOwner {
        require(status == WorkflowStatus.VotesTallied, "Le vote doit etre termine pour pouvoir le reinitialiser.");

        status = WorkflowStatus.RegisteringVoters;

        delete proposals;

        for (uint i = 0; i < voterAddresses.length; i++) {
            voters[voterAddresses[i]].hasVoted = false;
            voters[voterAddresses[i]].votedProposalId = 0;
        }
    }
}