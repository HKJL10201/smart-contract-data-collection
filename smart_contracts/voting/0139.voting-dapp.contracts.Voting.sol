pragma solidity ^0.4.18;

contract Voting {
  struct voter {
    address addr;
    uint tokens;
    uint[] tokensUsedPerCandidate;
  }

  mapping (address => voter) public voterInfo;
  mapping (bytes32 => uint) public votesReceived;

  bytes32[] public candidateList;

  uint public totalTokens;
  uint public balanceTokens;
  uint public tokenPrice;

  function Voting(uint tokens, uint pricePerToken, bytes32[] candidateNames) public {
    candidateList = candidateNames;
    totalTokens = tokens;
    balanceTokens = tokens;
    tokenPrice = pricePerToken;
  }

  function totalVotesFor(bytes32 candidate) view public returns (uint) {
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate, uint votesInTokens) public {
    uint index = indexOfCandidate(candidate);
    require(index != uint(-1));

    if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
      for(uint i = 0; i < candidateList.length; i++) {
        voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
      }
    }

    uint availableTokens = voterInfo[msg.sender].tokens - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
    require(availableTokens >= votesInTokens);

    votesReceived[candidate] += votesInTokens;

    voterInfo[msg.sender].tokensUsedPerCandidate[index] += votesInTokens;
  }

  function totalTokensUsed(uint[] _tokensUsedPerCandidate) private pure returns (uint) {
    uint totalUsedTokens = 0;
    for(uint i = 0; i < _tokensUsedPerCandidate.length; i++) {
      totalUsedTokens += _tokensUsedPerCandidate[i];
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

  function buy() payable public returns (uint) {
    uint tokensToBuy = msg.value / tokenPrice;
    require(tokensToBuy <= balanceTokens);
    voterInfo[msg.sender].addr = msg.sender;
    voterInfo[msg.sender].tokens += tokensToBuy;
    balanceTokens -= tokensToBuy;
    return tokensToBuy;
  }

  function tokensSold() view public returns (uint) {
    return totalTokens - balanceTokens;
  }

  function voterDetails(address user) view public returns (uint, uint[]) {
    return (voterInfo[user].tokens, voterInfo[user].tokensUsedPerCandidate);
  }

  function transferTo(address account) public {
    account.transfer(this.balance);
  }

  function allCandidates() view public returns (bytes32[]) {
    return candidateList;
  }
}
