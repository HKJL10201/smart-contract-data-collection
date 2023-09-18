// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../openzeppelin-contracts/contracts/math/SafeMath.sol";

contract MyERC20 is ERC20 {
    using SafeMath for uint256;
    bytes32[] public candidateList;
    uint256 public INITIAL_SUPPLY = 20000;

    uint256 public totalTokens;
    uint256 public balanceTokens;
    uint256 public tokenPrice = 10000000000000000;

    constructor() ERC20("MyToken", "MYT") {
        //_mint(msg.sender, INITIAL_SUPPLY);
        totalTokens = INITIAL_SUPPLY;
        balanceTokens = totalTokens;
        candidateList = [bytes32("Rama"), bytes32("Nick"), bytes32("Jose")];
    }
    
    struct voter {
    address voterAddress;
    uint256 tokensBought;
    uint256[] tokensUsedPerCandidate;
    }
   
    mapping(address => voter) public voterInfo;
   
    mapping(bytes32 => uint256) public votesReceived;


  function buy() payable public {
    uint256 tokensToBuy = msg.value / tokenPrice;
    require(tokensToBuy <= balanceTokens);
    voterInfo[msg.sender].voterAddress = msg.sender;
    voterInfo[msg.sender].tokensBought += tokensToBuy;
    balanceTokens -= tokensToBuy;
    _mint(msg.sender, tokensToBuy);
    //transfer(msg.sender, tokensToBuy);
    //_mint(msg.sender, tokensToBuy);
    //transferFrom(msg.sender, tokensToBuy);
    //emit Transfer(address(0), msg.sender, tokensToBuy);
  }



  function voteForCandidate(bytes32 candidate, uint256 tokens) public {
    // Check to make sure user has enough tokens to vote
    // Increment vote count for candidate
    // Update the voter struct tokensUsedPerCandidate for this voter 
     
    uint256 availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
   
    require(tokens <= availableTokens, "You don't have enough tokens");
    votesReceived[candidate] += tokens;
     
    if(voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
      for(uint i=0; i<candidateList.length; i++) { 
        voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
      }
    }
     
    uint256 index = indexOfCandidate(candidate);
    voterInfo[msg.sender].tokensUsedPerCandidate[index] += tokens;
    _burn(msg.sender, tokens);
  }
   
  function indexOfCandidate(bytes32 candidate) view public returns(uint) {
    for(uint256 i=0; i<candidateList.length; i++ ) {
      if (candidateList[i] == candidate) {
        return i;
      }
    }
    return uint(-1);
  }

  function totalTokensUsed(uint256[] memory _tokensUsedPerCandidate) private pure returns (uint) {
    uint256 totalUsedTokens = 0;
    for(uint i=0; i<_tokensUsedPerCandidate.length; i++) {
      totalUsedTokens += _tokensUsedPerCandidate[i];
    }
    return totalUsedTokens;
  }

function voterDetails(address user) view public returns (uint256, uint256[] memory) {
    return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
  }
   
  function tokensSold() public view returns (uint256) {
    return INITIAL_SUPPLY - balanceTokens;
  }
   
  function allCandidates() public view returns (bytes32[] memory) {
    return candidateList;
  }
   
  function totalVotesFor(bytes32 candidate) public view returns (uint256) {
    return votesReceived[candidate];
  }

}

