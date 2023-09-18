pragma solidity >=0.4.22 <0.8.0;

contract Election{
	
	struct Candidate{
		uint id;
		string name;
		uint voteCount;
	}

	mapping(uint => Candidate) public candidates;
	uint public candidatesCount;

	constructor () public
	{
		addCandidate("ya");
		addCandidate("sin");
	}

	function addCandidate (string memory _name) private
	{
		candidatesCount++;
		candidates[candidatesCount]=Candidate(candidatesCount,_name,0);
	}
}