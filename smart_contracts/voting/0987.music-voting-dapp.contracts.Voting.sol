pragma solidity ^0.5.8;

// We have to specify what version of compiler this code will compile with

contract Voting {
	/* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */

	mapping(bytes32 => uint256) public votesReceived;

	/* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of candidates
  */

	bytes32[] public optionList;

	/* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */
	constructor(bytes32[] memory optionNames) public {
		optionList = optionNames;
	}

	// This function returns the total votes a candidate has received so far
	function totalVotesFor(bytes32 option) public view returns (uint256) {
		require(validOption(option));
		return votesReceived[option];
	}

	// This function increments the vote count for the specified candidate. This
	// is equivalent to casting a vote
	function voteForCandidate(bytes32 option) public {
		require(validOption(option));
		votesReceived[option] += 1;
	}

	function validOption(bytes32 option) public view returns (bool) {
		for (uint256 i = 0; i < optionList.length; i++) {
			if (optionList[i] == option) {
				return true;
			}
		}
		return false;
	}
}
