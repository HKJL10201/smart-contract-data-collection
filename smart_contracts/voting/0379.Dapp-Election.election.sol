pragma solidity ^0.4.23;

contract Election{


	//just sytactic sugar
	//EVM not aware of them 
	struct Candidate{

		uint id;
		string name;
		uint voteCount;

	}

	//mapping as array use
	//not length defined thats why vairbale candidateCount

	mapping(address=>bool) public voters; 

	mapping(uint=>Candidate) public candidates;
	//if public getter present deault
	
	uint public candidateCount;

	function Election() public {

		addCandidate("Vaibhav Aggarwal");
		addCandidate("Shivam Aggarwal");

	}


	//candidate count public
	//public gives a getter function by itself(solidity)
	//functions in solidity allow to pass metadata
	

	//want contract to acces it
	function addCandidate (string _name) private{

		candidateCount++;

		candidates[candidateCount] = Candidate(candidateCount, _name, 0);
	}


	//voting function should be public
	function vote (uint _candidateId) public {

		//they have not voted earlier
		//sort of condn if evelauted true then forward
		require(!voters[msg.sender]);

		//valid voter
		require(_candidateId>=1 && _candidateId<=candidateCount);

		//record voter has voted
		voters[msg.sender]=true;

		//want to increse count
		candidates[_candidateId].voteCount++;
	}
}