pragma solidity ^0.4.11;

contract VoteWithTokens {
  
    struct voter {
        address voterAddress; 
        uint tokensBought;    
        uint[] tokensUsedPerCandidate; 
    }

    mapping (bytes32 => uint8) public votesReceived;
    mapping (address => voter) public voterInfo;

    bytes32[] public candidateList;

    uint public totalTokens; 
    uint public balanceTokens; 
    uint public tokenPrice; 

    function VoteWithTokens(uint tokens, uint pricePerToken, bytes32[] candidateNames) {
        candidateList = candidateNames;
        totalTokens = tokens;
        balanceTokens = tokens;
        tokenPrice = pricePerToken;
    }

    function totalVotesFor(bytes32 candidate) returns (uint8) {
        require(validCandidate(candidate) != false);
        return votesReceived[candidate];
    }

    function voteForCandidate(bytes32 candidate, uint8 votesInTokens) {
        uint index = indexOfCandidate(candidate);
        require(index != uint(-1));

        // msg.sender gives us the address of the account/voter who is trying
        // to call this function
        if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
          for(uint i = 0; i < candidateList.length; i++) {
            voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
          }
        }

        // Make sure this voter has enough tokens to cast the vote
        uint availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
        require(availableTokens >= votesInTokens);

        votesReceived[candidate] += votesInTokens;

        // Store how many tokens were used for this candidate
        voterInfo[msg.sender].tokensUsedPerCandidate[index] += votesInTokens;
    }

    // Return the sum of all the tokens used by this voter.
    function totalTokensUsed(uint[] _tokensUsedPerCandidate) private constant returns (uint) {
        uint totalUsedTokens = 0;
        for(uint i = 0; i < _tokensUsedPerCandidate.length; i++) {
          totalUsedTokens += _tokensUsedPerCandidate[i];
        }
        return totalUsedTokens;
    }

    function indexOfCandidate(bytes32 candidate) constant returns (uint) {
        for(uint i = 0; i < candidateList.length; i++) {
          if (candidateList[i] == candidate) {
            return i;
          }
        }
        return uint(-1);
    }

    function buy() payable returns (uint) {
        uint tokensToBuy = msg.value / tokenPrice;
        require(tokensToBuy <= balanceTokens);
        voterInfo[msg.sender].voterAddress = msg.sender;
        voterInfo[msg.sender].tokensBought += tokensToBuy;
        balanceTokens -= tokensToBuy;
        return tokensToBuy;
    }

    function tokensSold() constant returns (uint) {
        return totalTokens - balanceTokens;
    }

    function voterDetails(address user) constant returns (uint, uint[]) {
        return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
    }

    /*  All the ether sent by voters who purchased the tokens is in this
        contract's account. This method will be used to transfer out all those ethers in to another account. *** The way this function is written currently, anyone can call this method and transfer the balance in to their account. In reality, you should add check to make sure only the owner of this contract can cash out.
    */

    function transferTo(address account) {
        account.transfer(this.balance);
    }

    function allCandidates() constant returns (bytes32[]) {
        return candidateList;
    }

    function validCandidate(bytes32 candidate) returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
          if (candidateList[i] == candidate) {
            return true;
          }
        }
        return false;
    }
}

