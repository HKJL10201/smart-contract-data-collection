pragma solidity ^0.4.6;
// We have to specify what version of compiler this code will compile with

contract Voting {

  // We use the struct datatype to store the voter information.
  struct Voter {
    address voterAddress; // The address of the voter
    uint tokensBought;    // The total no. of tokens this voter owns
    uint[] tokensUsedPerCandidate; // Array to keep track of votes per candidate.
    /* We have an array called candidateList initialized below.
     Every time this voter votes with her tokens, the value at that
     index is incremented. Example, if candidateList array declared
     below has ["Rama", "Nick", "Jose"] and this
     voter votes 10 tokens to Nick, the tokensUsedPerCandidate[1]
     will be incremented by 10.
     */
  }

  // keep track of # votes per candidate
  mapping (bytes32 => uint) public votesReceived;
  // keep track of voters by their address
  mapping (address => Voter) public voterInfo;

  bytes32[] public candidateList;
  uint public totalTokens; // Total no. of tokens available for this election
  uint public balanceTokens; // Total no. of tokens still available for purchase
  uint public tokenPrice; // Price per token

  function Voting(uint _totalTokens, uint _tokenPrice, bytes32[] _candidateList) {
    totalTokens = _totalTokens;
    balanceTokens = _totalTokens;
    tokenPrice = _tokenPrice;
    candidateList = _candidateList;
  }

  function totalVotesFor(bytes32 candidate) constant returns (uint) {
    return votesReceived[candidate];
  }

  /* Instead of just taking the candidate name as an argument, we now also
   require the no. of tokens this voter wants to vote for the candidate
   */
  function voteForCandidate(bytes32 candidate, uint numTokens) {
    // ensure that candidate exists
    uint index = indexOfCandidate(candidate);
    if (index == uint(-1)) throw;


    // initialize voter tokensUsedPerCandidate array if necessary
    var voter = voterInfo[msg.sender];
    if (voter.tokensUsedPerCandidate.length == 0) {
      for (uint i = 0; i < candidateList.length; i++) {
        voter.tokensUsedPerCandidate.push(0);
      }
    }

    // ensure that voter has enough tokens
    uint availableTokens = voter.tokensBought - numTokensUsed(voter.tokensUsedPerCandidate);
    if (availableTokens < numTokens) throw;

    // update votes
    votesReceived[candidate] += numTokens;
    voter.tokensUsedPerCandidate[index] += numTokens;
  }

  // Return the sum of all the tokens used by this voter.
  function numTokensUsed(uint[] _tokensUsedPerCandidate) private constant returns (uint) {
    uint numTokens = 0;
    for (uint i = 0; i < candidateList.length; i++) {
      numTokens += _tokensUsedPerCandidate[i];
    }
    return numTokens;
  }

  function indexOfCandidate(bytes32 candidate) constant returns (uint) {
    for (uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) return i;
    }
    return uint(-1);
  }

  /* This function is used to purchase the tokens. Note the keyword 'payable'
   below. By just adding that one keyword to a function, your contract can
   now accept Ether from anyone who calls this function. Accepting money can
   not get any easier than this!
   */
  function buy() payable returns (uint) {
    uint numTokens = msg.value / tokenPrice;
    if (numTokens == 0 || numTokens > balanceTokens) throw;

    var voter = voterInfo[msg.sender];
    voter.voterAddress = msg.sender;
    voter.tokensBought += numTokens;

    balanceTokens -= numTokens;
    return numTokens;
  }

  function tokensSold() constant returns (uint) {
    return totalTokens - balanceTokens;
  }

  function voterDetails(address user) constant returns (uint, uint[]) {
    var voter = voterInfo[user];
    return (voter.tokensBought, voter.tokensUsedPerCandidate);
  }

  /* All the ether sent by voters who purchased the tokens is in this
   contract's account. This method will be used to transfer out all those ethers
   in to another account. *** The way this function is written currently, anyone can call
   this method and transfer the balance in to their account. In reality, you should add
   check to make sure only the owner of this contract can cash out.
   */
  function transferTo(address account) {
    if (!account.call.value(this.balance)()) throw;
  }

  function allCandidates() constant returns (bytes32[]) {
    return candidateList;
  }
}
