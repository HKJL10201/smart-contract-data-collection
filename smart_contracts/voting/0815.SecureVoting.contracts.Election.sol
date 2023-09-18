pragma solidity ^0.4.11;

contract Election {

	//model a candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount; 
	}

	//store the accounts which have votes
	mapping (address => bool) public voters;
	
	//storing the candidates
	mapping (uint => Candidate) public candidates;
	
	//storing candidate count 
	uint public candidateCount;

	//constructor
	function Election() public{
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	function addCandidate(string _name) private {
		candidateCount++;
		candidates[candidateCount] = Candidate(candidateCount, _name, 0);
	}

	function vote(uint _candidateId) public {
		//require that they haven't voted before
		require (!voters[msg.sender]);

		//require that voting is done for a valid candidate
		require(_candidateId > 0 && _candidateId <= candidateCount);
		
		//record that voter has voted
		voters[msg.sender] = true;

		//update candidate vote count
		candidates[_candidateId].voteCount++;
	}
}
