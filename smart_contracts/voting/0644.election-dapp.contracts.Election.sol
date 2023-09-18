pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT
import "./Register.sol";

contract Election {

	// Model a candidate
	struct Candidate {
		uint id;
		string name;
		uint voteCount;
	}
	// Store Candidates
	// Fetch Candidates
	mapping(uint => Candidate) public candidates;
	// Store Candidates count
	uint public candidatesCount;
	// Store accounts that have voted

	string public Question;
	address public RegistrationContractAddress;
	uint public StartElectionTime;
	uint public EndElectionTime;

	mapping(address => bool) public voters;
	bool public ended;



	// voted event
	event votedEvent(uint indexed _candidateId);

	// Constructor
	constructor (
		string memory _question, 
		string[] memory candidateNames,
		address _RegistrationContractAddress,
		uint256 _startElectionTime,
		uint256 _endElectionTime
		) {		
			Question = _question;
			for (uint i = 0; i < candidateNames.length; i++){
				addCandidate(candidateNames[i]);
			}
			RegistrationContractAddress = _RegistrationContractAddress;
			StartElectionTime = _startElectionTime; 
			EndElectionTime = _endElectionTime;
			ended = false;
	}

	function addCandidate(string memory _name) public payable {
		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}

    function isEligble(address _address) private returns(bool) {
	    Register reg = Register(RegistrationContractAddress);
    	return reg.isEligble(_address);
	}

	function vote(uint _candidateId) public {

		// require that they haven't voted before
		// require a valid candidate

		require(!voters[msg.sender] && 
			_candidateId > 0 && 
			_candidateId <= candidatesCount && 
			!ended && 
			isEligble(msg.sender) &&
			block.timestamp > StartElectionTime);

		// record that voter has voted
		voters[msg.sender] = true;

		// update candidate vote count
		candidates[_candidateId].voteCount ++;

		// trigger voting event
		emit votedEvent(_candidateId);
	}

	function endElection() public {

		require(ended == false && block.timestamp > EndElectionTime);

		ended = true;

	}
}
