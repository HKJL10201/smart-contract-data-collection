pragma solidity ^0.4.2;

contract Election {
	// Model a Candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}

	// Store Candidates
	// Fetch Candidates
	mapping(uint => Candidate) public candidates;

	// Store Candidates Count 
	uint public candidatesCount;

	// Constructor
	constructor () public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	function addCandidate (string _name) private {
		candidatesCount ++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}
	
}