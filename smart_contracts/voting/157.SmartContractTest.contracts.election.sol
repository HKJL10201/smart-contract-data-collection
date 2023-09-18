pragma solidity >=0.4.25 <0.6.0;

contract election{
	//Store candidate
	//Read Candidate
	//Constructor
	string public candidate;

	uint public someValue;

	constructor() public{
		candidate = "Candidate";
	}


  	function beforeEach() public{
    someValue = 5;
  	}

	function beforeEachAgain() public{
    someValue += 1;
  	}

}