pragma solidity ^0.4.18;
// We have to specify what version of compiler this code will compile with

contract Voting {
  /* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */

  struct voter {
  	address voterAddress;
  	uint tokensBought;
  	uint[] tokensUsedPerCandidate;
  }
  
  mapping (bytes32 => uint) public votesReceived;
  mapping (address => voter) public voterInfo;
  
  /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of candidates
  */
  
  bytes32[] public candidateList;
  uint public totalTokens;
  uint public balanceTokens;
  uint public tokenPrice;

  /* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */
  function Voting(uint tokens, uint pricePerToken, bytes32[] candidateNames) public {
    candidateList = candidateNames;
    totalTokens = tokens;
    balanceTokens = tokens;
    tokenPrice = pricePerToken;
  }

  function buy () payable public returns (uint){
  	uint tokensToBuy = msg.value / tokenPrice;
  	// if (tokensToBuy > balanceTokens) throw;
  	require (balanceTokens > tokensToBuy);
  	voterInfo[msg.sender].voterAddress = msg.sender;
  	voterInfo[msg.sender].tokensBought += tokensToBuy;
  	balanceTokens -= tokensToBuy;
  	return tokensToBuy;
  }

  // This function returns the total votes a candidate has received so far
  function totalVotesFor(bytes32 candidate) view public returns (uint) {
    //require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // This function increments the vote count for the specified candidate. This
  // is equivalent to casting a vote
  function voteForCandidate(bytes32 candidate, uint votesInTokens) public {
    //require(validCandidate(candidate));
    uint index = indexOfCandidate(candidate);
    require(index != uint(-1));
    if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0){
    	for(uint i = 0; i < candidateList.length; i++){
    		voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
    	}
    }
    uint availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
    require(availableTokens >= votesInTokens);
    votesReceived[candidate] += votesInTokens;
    voterInfo[msg.sender].tokensUsedPerCandidate[index] += votesInTokens;
  }

  function totalTokensUsed(uint[] _tokensUsedperCandidate) private pure returns (uint) {
  	uint totalUsedTokens = 0;
  	for(uint i = 0; i < _tokensUsedperCandidate.length; i++){
  		totalUsedTokens += _tokensUsedperCandidate[i];
  	}
  	return totalUsedTokens;
  }

  function indexOfCandidate(bytes32 candidate) view public returns (uint){
  	for(uint i = 0; i < candidateList.length; i++){
  		if (candidateList[i] == candidate){
  			return i;
  		}
  	}
  	return uint(-1);
  }

  function tokensSold() view public returns (uint) {
  	return totalTokens - balanceTokens;
  }

  function voterDetails( address user) view public returns (uint, uint[]){
  	return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
  }

  function transferTo(address account) public {
  	account.transfer(this.balance);
  }

  function allCandidates() view public returns (bytes32[]){
  	return candidateList;
  }

  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}