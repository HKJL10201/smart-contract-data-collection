// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

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
    mapping (address => Voter) public voters;
    WorkflowStatus status;
    Proposal[] proposals;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    function registerVoter(address _addressVoter) public onlyOwner() {
        require(!voters[_addressVoter].isRegistered, "Already registered");
        voters[_addressVoter] = Voter(true,false,0);
    }

    function beginProposalRegistration() public onlyOwner() {
        require(status == WorkflowStatus.RegisteringVoters, "Une session est deja en cours");
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(status);
    }

    function endProposalRegistration() public onlyOwner() {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "The registration session is not active");
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(status);
    }

    function beginVoting() public onlyOwner() {
        require(status == WorkflowStatus.ProposalsRegistrationEnded, "The proposal registration session is not ended");
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(status);
    }

    modifier check  {
        require(
            voters[msg.sender].isRegistered == true, 
            "You are not authorized"
        );
        _;
    }

    modifier checkStatus(WorkflowStatus _status, string memory _message) {
        require(
            status == _status,
            _message
        );
        _;
    }

    function submitProposal(string calldata _descriptionProposal) external 
    check 
    checkStatus(WorkflowStatus.ProposalsRegistrationStarted, "The administrator dont allow proposal registration anymore.") {
        proposals.push(Proposal(_descriptionProposal,0));
        emit ProposalRegistered(proposals.length);
    }

    function vote(uint _proposalID) external 
    check 
    checkStatus(WorkflowStatus.VotingSessionStarted, "The voting session is not active"){
        require(_proposalID < proposals.length,"Cet ID n'existe pas.");
        require(!voters[msg.sender].hasVoted, "Already voted.");
        voters[msg.sender].votedProposalId = _proposalID;
        voters[msg.sender].hasVoted = true;
        proposals[_proposalID].voteCount += 1;
        emit Voted(msg.sender, _proposalID);
    }

    function endVoting() external onlyOwner() 
    checkStatus(WorkflowStatus.VotingSessionStarted, "The vote is not active.") {
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(status);
    }

    function compileVote() public onlyOwner() {

        uint maxCount = 0;
        uint winningProposal;
        for (uint i=0;i < proposals.length; i++) {
            if (proposals[i].voteCount > maxCount) {
                maxCount = proposals[i].voteCount;
                winningProposal = i;
            }
        }
        winningProposalId = winningProposal;
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(status);
    }

    function getWinner() external view returns (uint){
        return winningProposalId;
    }

    function winnerProposalDetails() external view
            returns (string memory _winnerProposalDescription)
    {
        return proposals[winningProposalId].description;
    }

}
