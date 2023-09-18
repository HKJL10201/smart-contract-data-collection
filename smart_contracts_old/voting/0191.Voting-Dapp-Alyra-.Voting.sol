pragma solidity 0.6.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

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

Proposal[] public listProposal;

enum WorkflowStatus {		
RegisteringVoters,
ProposalsRegistrationStarted,
ProposalsRegistrationEnded,
VotingSessionStarted,
VotingSessionEnded,
VotesTallied
}

WorkflowStatus public state;

uint winningProposalId;

event VoterRegistered(address voterAddress);
event ProposalsRegistrationStarted();
event ProposalsRegistrationEnded();
event ProposalRegistered(uint proposalId);
event VotingSessionStarted();
event VotingSessionEnded();
event Voted (address voter, uint proposalId);
event VotesTallied();
event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
	

mapping (address => Voter) private _whitelist;


	function whitelist(address _address) public onlyOwner{
		require(state == WorkflowStatus.RegisteringVoters);
		require(!_whitelist[_address].isRegistered && _address != address(0), "Address already whitelisted or owner address");
		_whitelist[_address].isRegistered = true;
		emit VoterRegistered(_address);
	}

	    function isWhitelisted(address _address) public view onlyOwner returns(bool){
        require(_whitelist[_address].isRegistered, "Address isn't whitelisted yet");
        return _whitelist[_address].isRegistered;
    }

	function StartProposalsRegistration() public onlyOwner {
		require(state == WorkflowStatus.RegisteringVoters);
		emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
		state = WorkflowStatus.ProposalsRegistrationStarted;
	}

	function AddProposal(string memory _description) public {
		require(state == WorkflowStatus.ProposalsRegistrationStarted);
		Proposal memory proposal;
		proposal.description = _description;
		proposal.voteCount = 0;
		listProposal.push(proposal);
		uint proposalId = listProposal.length - 1;
		emit ProposalRegistered(proposalId);
	}

	function EndProposalsRegistration() public onlyOwner {
		require(state == WorkflowStatus.ProposalsRegistrationStarted);
		emit ProposalsRegistrationEnded();
		emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted , WorkflowStatus.ProposalsRegistrationEnded);
		state = WorkflowStatus.ProposalsRegistrationEnded;
	}

	function StartVotingSession() public onlyOwner {
		require(state == WorkflowStatus.ProposalsRegistrationEnded);
		emit VotingSessionStarted();
		emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded , WorkflowStatus.VotingSessionStarted);
		state = WorkflowStatus.VotingSessionStarted;
	}

	function Vote(uint _proposalId) public {
		require(isWhitelisted(msg.sender), "This address isn't whitelisted yet");
		require(!_whitelist[msg.sender].hasVoted, "You can only vote once");
		require(state == WorkflowStatus.VotingSessionStarted);
		_whitelist[msg.sender].hasVoted = true;
		_whitelist[msg.sender].votedProposalId = _proposalId;
		listProposal[_proposalId].voteCount += 1;
		emit Voted (msg.sender, _proposalId);
	}

	function EndVotingSession() public onlyOwner {
		require(state == WorkflowStatus.VotingSessionStarted);
		emit VotingSessionEnded();
		emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted , WorkflowStatus.VotingSessionEnded);
		state = WorkflowStatus.VotingSessionEnded;
	}

	function TalliesVote() public onlyOwner {
		require(state == WorkflowStatus.VotingSessionEnded);
		uint winningVoteCount = 0;

		for (uint p = 0; p < listProposal.length; p++) {
			if (listProposal[p].voteCount > winningVoteCount) {
				winningVoteCount = listProposal[p].voteCount;
				winningProposalId = p;
			}
		}
		emit VotesTallied();
		emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded , WorkflowStatus.VotesTallied);
		state = WorkflowStatus.VotesTallied;
	}

	function getWinner() public view returns (string memory, uint) {
		require(state == WorkflowStatus.VotesTallied);
		return(listProposal[winningProposalId].description, listProposal[winningProposalId].voteCount);

	}
}
 

