pragma solidity 0.5.0;

//Declare Contract
contract Election{
	//Model a candidate
	struct Candidate{
		//uint is "unsigned integer"
		uint id;
		string name;
		uint voteCount;
	}
	//Store candidates

	//Fetch candidates
	/*mapping in solidity is like an associative array or hash wherewe associate key value pairs with one another.
	In this case the key is the unsigned integer that corresponds to the candidate id and the value will be a candidate structure type.
	that is how we store the candidates. Remember the importance og having it as public is to generate the getter.
	In solidity there is no way to iterate over this mapping or to determine its size*/
	mapping(uint => Candidate) public candidates;


	//Store candidate count
	/*We will increment the candidatesCount every time we add a candidate. This will help in accessing a candidate 
	inside a loop.
	State variable (without an underscore at the begining); variable accessible inside the contract and represents data 
	that belongs to the entire contract */
	uint public candidatesCount;


	//Constructor - Will be ran whenever contract is deployed to the blockchain. Note that constructor name is same as contract name
	constructor() public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");

	}

	/*the local variable "_name" should be preappended with an underscore.
	It is private because oly the contract should be able to add a candidate. Not that the default for
	unsigned integer is one. */
	function addCandidate (string memory _name) private{
		candidatesCount ++;
		/*First refernce the candidates mapping. Then pass the key of the id of the candidate to be created. Then assign
		the new key to the value there. To the struct, the key, name, and vote which is zero is passed. */
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}
}