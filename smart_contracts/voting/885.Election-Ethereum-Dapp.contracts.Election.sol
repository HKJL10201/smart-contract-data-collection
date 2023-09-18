pragma solidity ^0.4.24;

contract Election{
	
	//Model a candidate. Struct is used to create models
	struct Candidate{
		uint id;
		string name;
		uint voteCount;
	}

	//Store candidates
	//Fetch candidate
	//mapping is kind of hashmap
	mapping(uint=>Candidate) public candidates;
	//store accounts that already have voted
	mapping(address=>bool) public voters;

	//Candidate count
	uint public candidateCount;

	//adding event 
	event votedEvent(
		uint indexed _candidateId
	);

	constructor() public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	//_name represent the local variable
	//made private to restrict usage from outside
	function addCandidate(string _name) private{
		candidateCount++;
		candidates[candidateCount] = Candidate(candidateCount,_name,0);
	}

	//This function does the voting 
	function vote(uint _candidateId) public {
		//validate the sender is not voted yet
		require(!voters[msg.sender]);
		//validate the candidateId passed is valid
		require(_candidateId > 0 && _candidateId <=candidateCount);
		//store that current user is voted already
		voters[msg.sender] = true;
		//update vote count
		candidates[_candidateId].voteCount++;

		//triggering he voted event
		votedEvent(_candidateId);
	}
}

// Some truffle console hacks
// 
//  initialize the app by Election.deployed().then(function(instance){app =instance;})	 
//
//  get the candidate by app.candidates(1).then(function(c){candidate =c;});
//
// candidates returns BigNumber,string, BigNumber
// get value from BigNumber by candidate[2].toNumber() 
// 

