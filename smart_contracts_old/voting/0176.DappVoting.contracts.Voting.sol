// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Voting is Ownable {

    uint public winningProposalId;
    WorkflowStatus public currentWorkflow;

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
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted(address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    mapping (address => Voter) public whitelist;
    address[] public addresses;
    Proposal[] public proposals;

    modifier onlyWhitelisted(address _address) {
        require(whitelist[_address].isRegistered == true, "Address not whitelisted");
        _;
    }

    modifier workflow(WorkflowStatus expectedWorkflow) {
        require(currentWorkflow == expectedWorkflow, "Worflow not respected");
        _;
    }

    function tallyVotes() external onlyOwner workflow(WorkflowStatus.VotingSessionEnded) {
        changeWorkflowStatus(WorkflowStatus.VotesTallied);
        emit VotesTallied();
    }

    function endVotingSession() external onlyOwner workflow(WorkflowStatus.VotingSessionStarted) {
        changeWorkflowStatus(WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
    }

    function registerVote(uint proposalId) external onlyWhitelisted(msg.sender) workflow(WorkflowStatus.VotingSessionStarted) {
        require(whitelist[msg.sender].hasVoted == false, "Address has already voted");
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount++;

        if (proposals[proposalId].voteCount > proposals[winningProposalId].voteCount) {
            winningProposalId = proposalId;
        }
        emit Voted(msg.sender, proposalId);
    }

    function startVotingSession() external onlyOwner workflow(WorkflowStatus.ProposalsRegistrationEnded) {
        changeWorkflowStatus(WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }

    function endProposalsRegistration() external onlyOwner workflow(WorkflowStatus.ProposalsRegistrationStarted) {
        changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
    }

    function registerProposal(string calldata description) external onlyWhitelisted(msg.sender) workflow(WorkflowStatus.ProposalsRegistrationStarted) {
        proposals.push(Proposal(description, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    function startProposalsRegistration() external onlyOwner workflow(WorkflowStatus.RegisteringVoters) {
        changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
    }

    function changeWorkflowStatus(WorkflowStatus newStatus) internal {
        emit WorkflowStatusChange(currentWorkflow, newStatus);
        currentWorkflow = newStatus;
    }

    function addToWhitelist(address _address) external onlyOwner workflow(WorkflowStatus.RegisteringVoters) {
        require (whitelist[_address].isRegistered == false, "Address already whitelisted");
        whitelist[_address].isRegistered = true;
        addresses.push(_address);
        emit VoterRegistered(_address);
    }

    function getVoter(address _address) public view returns(Voter memory) {
        return whitelist[_address];
    }

    function getAddresses() public view returns(address[] memory){
        return addresses;
    }

    function getProposals() public view returns(Proposal[] memory){
        return proposals;
    }

    function getWorkflow() public view returns(WorkflowStatus){
       return currentWorkflow;
    }

    function getWinningProposalId() public view returns(uint){
       return winningProposalId;
    }
}