pragma solidity ^0.5.8;

contract Election {
	
	// Model a candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}
	
	// Read/Write Candidates
	mapping(uint => Candidate) public candidates;
	
	// Store accounts that have voted
	mapping(address => bool) public voters;

	// Store Candidates Count
	uint public candidatesCount;

	constructor() public {
		
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	
	}
	
	event votedEvent (
		uint indexed _candidateId
	);


	function addCandidate (string memory _name) private {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

	function vote(uint _candidateID) public {
		// require that they havent voted before
		require(!voters[msg.sender]);

		//require a valid candidate
		require(_candidateID > 0 && _candidateID <= candidatesCount);

		//record that voter has voted
		voters[msg.sender] = true;

		//update candidate vote count
		candidates[_candidateID].voteCount++;

		//trigger voted event
		emit votedEvent(_candidateID);
	}
}
