pragma solidity ^0.4.17;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting{
Voting voting = Voting(DeployedAddresses.Voting());

	bytes32 public assignedCandidate;

	function testGetCandidateNames() public {
	bytes32[] memory newList;

	voting.getCandidateNames(newList);

	assignedCandidate= voting.candidateList(1);
	bytes32 originalCanddate = newList[1];

	Assert.equal(assignedCandidate,originalCanddate,"Failed, Candidate list not assigned.");
	}



//Below function tests both voting and retrieivng the vote count

	function testVoteForCandidate() public {
	voting.voteForCandidate(assignedCandidate);
	uint startValue = voting.totalVotesFor(assignedCandidate);
	voting.voteForCandidate(assignedCandidate);
	uint endValue = voting.totalVotesFor(assignedCandidate);

	Assert.isAbove(endValue,startValue, "Failed. Did not increment.");
	}

//Below function tests retreiving array vote count of ALL candidates

	function testGetAllCandVotes() public {
	voting.totalVotesForAll();
	uint voteCountFromList = voting.candidatesVotes(1);
	uint voteCountFromFunction = voting.totalVotesFor(assignedCandidate);

	Assert.equal(voteCountFromList,voteCountFromFunction,"Failed.");
	}



}


