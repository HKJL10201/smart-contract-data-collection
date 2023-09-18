pragma solidity ^0.4.18;

contract Voting {

	struct voter {
		// address of the voter
		address addr;

		// number of tokens owned by the voter
		uint tokensTotal;
		
		// number of tokens available for the voter
		uint tokensAvailable;

		// number of tokens used for voting for each candidate
		// SUM tokensUsedPerCandidate <= tokensNum
		uint[] tokensUsedPerCandidate;
	}


	// all participating voters
	mapping (address => voter) public voters;

	// list of candidate's names
	string[] public candidates;

	// number of votes per candidate
	uint[] votes;

	// total number of tokens available
	uint public tokensTotal;

	// number of tokens still available for purchase
	uint public tokensAvailable;

	// wei per token
	uint public tokenPriceInWei;
	
	function initTokens(uint tokensNum, uint _tokenPriceInWei) public {
		tokensTotal = tokensNum;
		tokensAvailable = tokensNum;
		tokenPriceInWei = _tokenPriceInWei;
	}

	function addCandidate(string candidate) public {
		// new candidate
		candidates.push(candidate);
		// has 0 votes
		votes.push(0);
	}

	function deleteCandidate(string candidate) public {
		uint256 idx = getIndexByName(candidate);

		candidates[idx] = candidates[candidates.length-1];
		delete candidates[candidates.length-1];
		candidates.length--;

		votes[idx] = votes[votes.length-1];
		delete votes[votes.length-1];
		votes.length--;
	}

	function getCandidatesNumber() view public returns(uint256) {
		return candidates.length;
	}

	function getCandidateByIndex(uint256 idx) view public returns(string) {
		require(idx < candidates.length);
		return candidates[idx];
	}

	function getVotesByIndex(uint256 idx) view public returns(uint) {
		require(idx < votes.length);
		return votes[idx];
	}

	function getVotesByName(string candidate) view public returns(uint) {
		uint256 idx = getIndexByName(candidate);
		return votes[idx];
	}

	function voteByIndex(uint256 idx, uint tokensNum) public returns (uint){
		// ensure operation is reasonable
		require(tokensNum >= 0);
		require(voters[msg.sender].tokensAvailable >= tokensNum);
		require(idx < votes.length);
		
		// vote
		votes[idx] += tokensNum;
		voters[msg.sender].tokensAvailable -= tokensNum;

		return votes[idx];
	}

	function voteByName(string candidate, uint tokensNum) public returns (uint) {
		uint256 idx = getIndexByName(candidate);
		return voteByIndex(idx, tokensNum);
	}

	function getIndexByName(string candidate) view public returns (uint256) {
		for (uint256 i = 0; i < candidates.length; i++) {
			if (keccak256(candidates[i]) == keccak256(candidate)) {
				return i;
			}
		}
		
		// since throw is deprecated
		require(i < candidates.length);
		// this code should not be reached
		return i;
	}

	function buy() payable public returns (uint) {
		require(tokenPriceInWei > 0);

		// how many tokens can we buy for this payment
		uint tokensNum = msg.value / tokenPriceInWei;

		// ensure tokens available
		require(tokensNum <= tokensAvailable);
		
		// credit tokens to voter
		voters[msg.sender].addr = msg.sender;
		voters[msg.sender].tokensTotal += tokensNum;
		voters[msg.sender].tokensAvailable += tokensNum;

		// debit tokens from available supply
		tokensAvailable -= tokensNum;

		return tokensNum;
	}

	function transferTo(address to) public {
		to.transfer(this.balance);
	}

	function tokensSold() view public returns(uint) {
		return tokensTotal - tokensAvailable;
	}
}

