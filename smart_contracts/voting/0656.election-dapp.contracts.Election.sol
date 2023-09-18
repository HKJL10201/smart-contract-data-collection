pragma solidity ^0.5.8;

contract Election {
	// Model candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}
	// Store accounts that have voted
	mapping(address => bool) public voters;
	// Store candidate
	// Fetch candidate
	mapping(uint => Candidate) public candidates;
	// Store candidate count
	uint public candidatesCount;

	constructor() public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	function addCandidate (string memory _name) private {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

	function vote (uint _candidateId) public {
		// require they haven't voted before
		require(!voters[msg.sender],"User has voted before!");

		// require a valid candidate
		require(_candidateId>0 && _candidateId<=candidatesCount, "Invalid Candidate!");

		// record that voter has voted
		voters[msg.sender] = true;

		// update candidate vote count
		candidates[_candidateId].voteCount++;
	}
}