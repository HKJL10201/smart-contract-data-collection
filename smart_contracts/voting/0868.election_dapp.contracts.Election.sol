pragma solidity ^0.4.2;

contract Election {
	//model a candidate
	struct Candidate{
		uint id;
		string name;
		uint voteCount;
	}

	//Store accts that have voted
	mapping(address => bool) public voters;
	//store candidates
	//fetch candidates
	mapping(uint => Candidate) public candidates;
	//store candidates count 
	uint public candidatesCount;
	uint public commitPhaseEndTime;
	//uint public initialTime;
	bool public timeOver;
	uint public currentTime;
	//uint voteFee = 0.5 ether;


	//voted event
	event votedEvent (
		uint indexed _candidateId

		);
	//event timeUp
	event timeEvent ();

	constructor() public {
		uint _commitPhaseLengthInSeconds;
		//if (_commitPhaseLengthInSeconds < 30) {
        //    throw;
        //}
		_commitPhaseLengthInSeconds = 71000;
		//currentTime = now;
		commitPhaseEndTime = now + _commitPhaseLengthInSeconds * 1 seconds;
		addCandidate("candidate1");
		addCandidate("candidate2");
		addCandidate("candidate3");
		addCandidate("candidate4");
	}

	function addCandidate (string _name) private {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name,0);
	}

	function vote (uint _candidateId) public {
		// require that voting time is on
		if (now > commitPhaseEndTime) revert();
		// require that they havent voted before
		require(!voters[msg.sender]);

		// require a valid candidate
		require(_candidateId > 0 && _candidateId <= candidatesCount);
		// require voteFee is paid
		//require(msg.value == voteFee);

		//record that voter has voted
		voters[msg.sender] = true;

		// update candidate vote count
		candidates[_candidateId].voteCount ++;

		//trigger voted event
		votedEvent(_candidateId);
	}

    function nowTime () public returns(uint) {
        currentTime = now;
		return currentTime;
	}

	function timeOut () public returns(bool) {
        
		if (now > commitPhaseEndTime) {
			timeOver = true;
			return timeOver;
		}
		else {
			timeOver = false;
			return timeOver;
		}
		timeEvent();
	}

}
