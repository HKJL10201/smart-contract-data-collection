pragma solidity 0.5.16;

contract Election{

	//model of a Candidate
	struct Candidate{
		uint id;
		string name;
		uint votecount;
	}
	//storing the voters
	mapping(address => bool) public voters;
	//Fetch candidate
	//Store candidates
	//mapping each candidate via its id 
	//When we add a candidate to our mapping we are changing the state of the contract
	mapping(uint => Candidate) public candidates;

	//store Candidate count
	uint public candidatesCount;
	
	// Declare an event
	event votedEvent(
		uint indexed _candidateID
	);

	constructor() public{
		//constructor
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
		
	}

	function addCandidate(string memory _name) private{
		candidatesCount ++;
		candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
	}

	function vote(uint _candidateID) public{
		//Identify the voter and allow him to vote only once

		require (!voters[msg.sender]);
		require(_candidateID >0 && _candidateID<=candidatesCount);
		
		voters[msg.sender]=true;
		//increment the vote
		candidates[_candidateID].votecount++;
		//trigger voted event
		emit votedEvent(_candidateID);
	}
}
