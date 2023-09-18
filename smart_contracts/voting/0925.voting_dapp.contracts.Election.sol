pragma solidity ^0.5.0;

contract Election {

	// model a candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}

	// store accounts that have voted
	mapping (address => bool) public voters;
	
	
	// store candidates
	mapping (uint => Candidate) public candidates;
	
	// store candidates count
	uint public candidatesCount;

	// voted event
	event votedEvent (
		uint indexed _candidateId
	);

	constructor () public {
		addCandidate("Emmanuel");
		addCandidate("Billy");
	}

	// add candidate
	function addCandidate (string memory _name) private {
		candidatesCount ++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}
	
	// vote
	function vote (uint _candidateId) public {

		// require that the voter hasn't voted before
		require (!voters[msg.sender]);		

		// require a valid candidate
		require (_candidateId > 0 && _candidateId <= candidatesCount);		

		// record that voter has voted
		voters[msg.sender] = true;
		
		// update candidate's vote count
		candidates[_candidateId].voteCount ++;

		// trigger a voted event
		emit votedEvent(_candidateId);
	}
	
}
