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

	uint[] resultsArray;
	
    constructor(bytes32[] _candidateList) public {
        candidateList = _candidateList;
        chairman = msg.sender;
		resultsArray = new uint[](candidateList.length);
    }
	
    function getCandidates() view public returns (bytes32[]) {
        return candidateList;
    }
	
	function getChairmanAddress() view public returns (address) {
		return chairman;
	}
	
	function vote(bytes32 candidate) public returns (bool) {
		require(validCandidate(candidate));
		if (!voterStructs[msg.sender].exists) {
			voterStructs[msg.sender] = Voter(msg.sender, candidate, true);
			voteTracker[candidate] += 1;
			return true;
		}
		return false;
	}
	
	function results() public returns (bytes32[], uint[]) {
		for (uint i = 0; i < candidateList.length; i++) {
			resultsArray[i] = voteTracker[candidateList[i]];
		}
		return (candidateList, resultsArray);
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