pragma solidity ^0.4.11;

contract smartVoting {
	// maps candidates (bytes32) with number of votes recived (uint8)
	mapping (bytes32 => uint8) public votesReceived;

	// a separate array of candidate names, since Solidity lacks a .keys method
	bytes32[] public candidateList;

	// constructor function
	function smartVoting(bytes32[] candidateNames) {
		candidateList = candidateNames;
	}

	function totalVotesFor(bytes32 candidate) returns (uint8) {
		require(validCandidate(candidate));
		return votesReceived[candidate];
	}

	function voteForCandidate(bytes32 candidate) {
		require(validCandidate(candidate));
		votesReceived[candidate] += 1;
	}

	function validCandidate(bytes32 candidate) returns (bool) {
		for(uint i = 0; i < candidateList.length; i++) {
			if (candidateList[i] == candidate)
				return true;
		}
		return false;
	}


}