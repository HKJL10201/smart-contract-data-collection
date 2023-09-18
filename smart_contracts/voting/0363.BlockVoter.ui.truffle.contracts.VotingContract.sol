pragma solidity ^0.4.22;

contract VotingContract {

	struct Voter {
		address voterAddress;
		bytes32 candidateVotedFor;
		bool exists;
	}
	
	mapping(address => Voter) public voterStructs;
	
	mapping(bytes32 => uint) voteTracker;
	
		// the list of candidates
    bytes32[] public candidateList;
	
	// the address of the node who initiated the poll
    address public chairman;

	bytes32 name;

	bytes32 description;
	
    constructor(bytes32 _name, bytes32 _description, bytes32[] _candidateList) public {
        candidateList = _candidateList;
        chairman = msg.sender;
		name = _name;
		description = _description;
    }

	function getName() view public returns(bytes32) {
		return name;
	}

	function getDescription() view public returns(bytes32) {
		return description;
	}
	
    function getCandidates() view public returns (bytes32[]) {
        return candidateList;
    }
	
	function getChairmanAddress() view public returns (address) {
		return chairman;
	}
	
	function vote(bytes32 candidate) public returns (bool) {
		// for now just increment the count
		require(validCandidate(candidate));
		voteTracker[candidate] += 1;
		return true;
		// TODO -  future state
		// if (!voterStructs[msg.sender].exists) {
		// 	voterStructs[msg.sender] = Voter(msg.sender, candidate, true);
		// 	voteTracker[candidate] += 1;
		// 	return true;
		// }
		// return false;
	}

	function getResultsForCandidate(uint index) view public returns (uint) {
		return voteTracker[candidateList[index]];
	}
	
	function validCandidate(bytes32 candidate) view public returns (bool) {
		for (uint i = 0; i < candidateList.length; i++) {
			  if (candidateList[i] == candidate) {
                return true;
            }
		}
		return false;
	}	
}