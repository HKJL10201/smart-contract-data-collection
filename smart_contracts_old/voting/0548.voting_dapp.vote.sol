pragma solidity ^0.4.19;

contract Vote {
	mapping (bytes32 => uint8) public votesReceived;
	bytes32[] public ballotList;

	function Vote(bytes32[] ballotItems) {
		ballotList = ballotItems;
	}

	function totalVotes(bytes32 ballotItem) returns (uint8) {
		return votesReceived[ballotItem];
	}

	function voteForBallotItem(bytes32 ballotItem) {
		if(validBallotItem(ballotItem) == false) throw;
		votesReceived[ballotItem]++;
	}

	function validBallotItem(bytes32 ballotItem) returns (bool) {
		for(uint i = 0; i < ballotList.length; i++) {
			if (ballotList[i] == ballotItem) {
				return true;
			}
		}
	}
}