pragma solidity ^0.5.0;

contract Election {
	// Model a Candidate	
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}

	//Store Accounts that have voted
	mapping(address => bool) public voters;
	//Store Candidates
	//Fetch Candidates
	mapping(uint => Candidate) public candidates;
	//Store Candidates Count
	uint public candidatesCount;
	
	// voted event
	event votedEvent (
		uint indexed _candidateId
	);

	// Constructor
	constructor() public {
		addCandidate("BJP");
		addCandidate("Congress");
	}

	function addCandidate (string memory _name) private {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

	function vote (uint _candidateId) public {
		// require that an account votes only once and hasn't voted before
		require(!voters[msg.sender]);

		// require to only vote for valid candidates
		require(_candidateId > 0 && _candidateId <= candidatesCount);
		// record that voter has voted
		// msg.sender reads the metadata to get account address of voter
		voters[msg.sender] = true; 

		// update candidate vote Count
		candidates[_candidateId].voteCount ++;

		// trigger voted event
		emit votedEvent(_candidateId);
	} 
}