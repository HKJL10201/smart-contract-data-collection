pragma solidity ^0.5.0;

contract Election {
	//model a Candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}
	//Read/write Candidates
	mapping(uint => Candidate) public candidates;

	mapping(address => bool) public voters;

	function vote (uint _candidateId) public {
			//require that they haven't voted before
			require(!voters[msg.sender], "You have voted before");

			//require a valid candidate
			require(_candidateId > 0 && _candidateId <= candidatesCount, "Please vote for a vaild candidate");
			//record that voted has voted
			voters[msg.sender] = true;
			//update candidate vote Count
			candidates[_candidateId].voteCount++;

			//trigger voted event
			emit votedEvent(_candidateId);
	}

	//Store Candidates Count
	uint public candidatesCount;

	constructor() public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	function addCandidate (string memory _name) private {
		candidatesCount ++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

	event votedEvent (
		uint indexed _candidateId
	);


}
