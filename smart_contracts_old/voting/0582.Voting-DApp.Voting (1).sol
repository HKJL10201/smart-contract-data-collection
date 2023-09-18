pragma solidity ^0.5.9;

import './AccessControlled.sol';

contract Voting is AccessControlled{


	// Vote Struct. It defines a custom type to be used to store values for every vote received.
	struct Vote {
		address receiver;
		uint256 timestamp;
	}

	// The main votes state variable of the type 'mapping'. This will be like a hash-map of all votes collected from each voter.
	mapping(address => Vote) public votes;

	// Define events we wish to emit
	event AddVote(address indexed voter, address receiver, uint256 timestamp);
	event RemoveVote(address voter);
	event StartVoting(address startedBy);
	event StopVoting(address stoppedBy);

	// Main constructor of the contract. It sets the owner of the contract and the voting status flag to false.
	constructor() public {
		isVoting = false;
	}

	function startVoting() external returns(bool) {
		isVoting = true;
		emit StartVoting(msg.sender);
		return true;
	}

	function stopVoting() external isVotingOpen returns(bool) {
		isVoting = false;
		emit StopVoting(msg.sender);
		return true;
	}

	function addVote(address receiver) external returns(bool) {
	
		// Set values for the Vote struct
		votes[msg.sender].receiver = receiver;
		votes[msg.sender].timestamp = now;

		emit AddVote(msg.sender, votes[msg.sender].receiver, votes[msg.sender].timestamp);
		return true;
	}

	function removeVote() external returns(bool) {

		delete votes[msg.sender];

		emit RemoveVote(msg.sender);
		return true;
	}

	function getVote(address voterAddress) external view returns(address candidateAddress) {
		return votes[voterAddress].receiver;
	}
}