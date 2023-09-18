pragma solidity ^0.4.18;

contract Voting {
  // voter information:
  struct voter {
    address voterAddress;
    uint tokensBought;
    uint[] tokensUsedPerCandidate; // number of votes per candidate
    /* essentially, everytime this voter votes with their tokens, the value at that index
    of the candidate in candidateList is incremented.
    */
  }
  /* a mapping is the same thing as a hash table. e.g. the key of the mapping is the candidate's name,
  and the number of votes received is the value stored.
  */
  mapping (bytes32 => uint) public votesReceived;
  mapping (address => voter) public voterInfo;

  // this is the list of candidates
  bytes32[] public candidateList;
  uint public totalTokens; // total tokens available for this election
  uint public balanceTokens; // tokens still available for purchase
  uint public tokenPrice;

  /* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */
  constructor (uint tokens, uint pricePerToken, bytes32[] candidateNames) public {
    candidateList = candidateNames;
    totalTokens = tokens;
    balanceTokens = tokens;
    tokenPrice = pricePerToken;
  }

  function buy() payable public returns (uint) {
    uint tokensToBuy = msg.value / tokenPrice;
    require(tokensToBuy < balanceTokens);
    voterInfo[msg.sender].voterAddress = msg.sender;

    voterInfo[msg.sender].tokensBought += tokensToBuy;
    balanceTokens -= tokensToBuy;
    return tokensToBuy;
  }

  function totalVotesFor(bytes32 candidate) view public returns (uint) {
    return votesReceived[candidate];
  }

  // takes candidate's name and number of tokens the voter wants to use to vote for the candidate.
  function voteForCandidate(bytes32 candidate, uint votesInTokens) public {
    uint index = indexOfCandidate(candidate);
    require(index != uint(-1));

    if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
      for(uint i = 0; i < candidateList.length; i++) {
        voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
      }
    }

    // checking the token balance of the voter
    uint availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
    require(availableTokens >= votesInTokens);

    votesReceived[candidate] = votesReceived[candidate] + votesInTokens;

    // storing the amount of tokens used to vote for this candidate
    voterInfo[msg.sender].tokensUsedPerCandidate[index] = voterInfo[msg.sender].tokensUsedPerCandidate[index] + votesInTokens;
  }

  // returns total # of tokens used by voter
  function totalTokensUsed(uint[] _tokensUsedPerCandidate) private pure returns (uint) {
    uint totalUsedTokens = 0;
    for(uint i = 0; i < _tokensUsedPerCandidate.length; i++) {
      totalUsedTokens = totalUsedTokens + _tokensUsedPerCandidate[i];
    }
    return totalUsedTokens;
  }

  function indexOfCandidate(bytes32 candidate) view public returns (uint) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return i;
      }
    }
    return uint(-1);
  }

  function tokensSold() view public returns (uint) {
    return totalTokens - balanceTokens;
  }

  function voterDetails(address user) view public returns (uint, uint[]) {
    return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
  }

  function transferTo(address account) public {
    account.transfer(address(this).balance);
  }

  function allCandidates() view public returns (bytes32[]) {
    return candidateList;
  }
}
