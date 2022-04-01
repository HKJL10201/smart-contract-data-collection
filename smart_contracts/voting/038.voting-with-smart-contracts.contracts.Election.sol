pragma solidity ^0.4.24;

contract Election{
	//model candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}
	//Store Candidates
	//string public candidate;
	
	//voters who have voted
	mapping(address => bool) public voters; //dictionary like in python

	//Fetching a candidate
	mapping(uint => Candidate) public candidates;//dict holding vote count and candidate's details
	//store candidates count
	uint public candidatesCount;

	//constructor
	function Election () public {
		//candidate = "Rudy";
		addCandidate("Dexter");
		addCandidate("Heisenberg");
		addCandidate("Bruce Wayne");
	}

	function addCandidate (string _name) private {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

	//this function will vote to a specific candidate.
	//candidate id will be passed to the function,
	//solidity allows more parameters than specified in fn.
	//these parameters are metadata used as "{ from: web3.eth.accounts[0] }"
	function vote(uint _candId) {
		//check conditions of voter and candidate before casting votes

		//1. condition: allow only those voters who haven't voted yet
		require(!voters[msg.sender]);

		//2. condition: voter votes to existing candidate
		require(_candId > 0 && _candId <= candidatesCount);

		voters[msg.sender] = true; //this tracks the voter has voted

		//updating candidate's vote count
		candidates[_candId].voteCount++;	
	}
}