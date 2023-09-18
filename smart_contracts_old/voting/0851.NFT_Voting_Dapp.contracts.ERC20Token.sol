// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin-contracts/contracts/math/SafeMath.sol";

contract ERC20Token is IERC20 {
  using SafeMath for uint256;
  bytes32[] public candidateList;
   
  uint public totalTokens;
  uint public balanceTokens;
  uint public tokenPrice;
   
  // what is the voter address?
  // total tokens purchased
  // tokens voted per candidate 
   
  struct voter {
    address voterAddress;
    uint tokensBought;
    uint256[] tokensUsedPerCandidate;
  }
   
  mapping(address => voter) public voterInfo;
   
  mapping(bytes32 => uint256) public votesReceived;

  string public symbol;
  string public name;
  uint8 public decimals;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;
  
  constructor(uint256 _totalTokens, uint256 _tokenPrice, bytes32[] memory _candidateNames)  {
    symbol = "NCToken";
    name = "NCSOFT TOKEN";
    decimals = 0;
    totalTokens = _totalTokens;
    balanceTokens = _totalTokens;
    tokenPrice = _tokenPrice;
    candidateList = _candidateNames;
    emit Transfer(address(0), msg.sender, totalTokens);
  }
   
  //1. Users should be able to purchase tokens 
  //2. Users should be able to vote for candidates with tokens
  //3. Anyone should be able to lookup voter info
  

  function buy() payable public {
    uint tokensToBuy = msg.value / tokenPrice;
    require(tokensToBuy <= balanceTokens);
    voterInfo[msg.sender].voterAddress = msg.sender;
    voterInfo[msg.sender].tokensBought += tokensToBuy;
    balanceTokens -= tokensToBuy;
    
    emit Transfer(address(0), msg.sender, tokensToBuy);
  }
/*
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return voterInfo[_owner].tokensBought - totalTokensUsed(voterInfo[_owner].tokensUsedPerCandidate);
  }
*/

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
    return totalTokens - balanceTokens;
  }
   
  function allCandidates() public view returns (bytes32[] memory) {
    return candidateList;
  }
   
  function totalVotesFor(bytes32 candidate) public view returns (uint256) {
    return votesReceived[candidate];
  }


//-------------------------------------------------------ERC20 Standard Interface Implementation---------------------------------------------------

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view override returns (uint256) {
        return totalTokens-voterInfo[address(0)].tokensBought;
        //return totalTokens  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view override returns (uint256) {
        //return voterInfo[tokenOwner].tokensBought;
        return (voterInfo[tokenOwner].tokensBought - totalTokensUsed(voterInfo[tokenOwner].tokensUsedPerCandidate));
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool) {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], tokens);
        balances[to] = SafeMath.add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address owner, address spender, uint256 tokens) public override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool) {
        balances[from] = SafeMath.sub(balances[from], tokens);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], tokens);
        balances[to] = SafeMath.add(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function getBalances(address from) public view returns (uint256) {
      return balances[from];
    }

    function getAllowed(address from) public view returns (uint256) {
      return allowed[from][msg.sender];
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return allowed[tokenOwner][spender];
    }

}