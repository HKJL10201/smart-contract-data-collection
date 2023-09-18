pragma solidity ^0.4.23;

contract Voting {

	address owner;
	
	// Modal a candidate
	struct Candidate {
		string name;
		string party;
		bool doesExist;
	}

	// Modal a voter
	struct Voter {
		uint vid;
		uint candidateIDVote;
		bool isVoted;
	}

	// store and fetch candidates
	mapping(uint => Candidate) public candidates;

	// store and fetch voters
	mapping(uint => Voter) public voters;

	// unique id candidates/voters count
	uint public candidateCount;
	uint public voterCount;

	// voted event
    event votedEvent (uint _vid, uint _candidateId);

    // candidate added Event
    event addedCandidate(uint indexed _candidateId);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *  These functions perform transactions, editing the mappings *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

	function addCandidate(string name, string party) onlyOwner public {
		uint candidateId = candidateCount++;

		// creates a new candidate
		candidates[candidateId] = Candidate(name, party, true);

		// emit the cadidate added event
		emit addedCandidate(candidateId);
	}

	function vote(uint vid, uint candidateId) public {
		// add to voters array if candidate exists
		if((candidates[candidateId].doesExist == true) && hasVoterVoted(vid) == false) {
			uint voterId = voterCount++;
			voters[voterId] = Voter(vid, candidateId, true);
			emit votedEvent(vid, candidateId);
		}
	}

	/* * * * * * * * * * * * * * * * * * * * * * * * * * 
     *  Getter Functions, marked by the key word "view" *
     * * * * * * * * * * * * * * * * * * * * * * * * * */

	function numberOfVotes(uint candidateId) public view returns(uint) {
		uint numOfVotes = 0;

		for(uint i=0; i < voterCount; i++) {
			if(voters[i].candidateIDVote == candidateId) {
				numOfVotes++;
			}
		}

		return numOfVotes;
	}

	function hasVoterVoted(uint vid) public view returns(bool) {
		for(uint i=0; i < voterCount; i++) {
			if(voters[i].vid == vid && voters[i].isVoted == true) {
				return true;
			}
		}
		return false;
	}

	function getNumOfCandidates() public view returns(uint) {
        return candidateCount;
    }

    function getNumOfVoters() public view returns(uint) {
        return voterCount;
    }

    function getCandidate(uint candidateId) public view returns(uint, string, string) {
    	return (candidateId, candidates[candidateId].name, candidates[candidateId].party);
    }
}