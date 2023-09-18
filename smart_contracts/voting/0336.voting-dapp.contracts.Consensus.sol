pragma solidity ^0.4.24; 

contract Consensus {
  //variables
  uint public tokenPrice = 0.01 ether;
  mapping (address => director) public directorInfo;
  mapping (bytes32 => uint) public votesReceived;
  bytes32[] public register;
  uint public tokens; 
  uint public balance;
  address owner;

  struct director {
    address directorAddress;
    uint tokensBought;
    uint[] option;
  }

  //constructor
  constructor(uint _tokens, bytes32[] proposals) public {
    register = proposals;
    tokens = _tokens;
    balance = _tokens;
    owner = msg.sender;
  }

  //modificador
  modifier onlyOwner(){
    if(owner != msg.sender)
      revert();
    _;
  }

  //metodos
  function buyTokens() payable public returns (uint){
    uint tokensToBuy = msg.value / tokenPrice;
    require(tokensToBuy <= balance);
    directorInfo[msg.sender].directorAddress = msg.sender;
    directorInfo[msg.sender].tokensBought += tokensToBuy;
    balance -= tokensToBuy;
    return tokensToBuy;
  }

  function sold() view public returns (uint) {
    return tokens - balance;
  }

 function totalVotesFor(bytes32 candidate) view public returns (uint) {
  return votesReceived[candidate];
 }

  function voteForCandidate(bytes32 candidate, uint votesInTokens) public {
    uint index = searchCandidate(candidate);

    if (directorInfo[msg.sender].option.length == 0) {
      for(uint i = 0; i < register.length; i++) {
        directorInfo[msg.sender].option.push(0);
      }
    }

    uint availableTokens = directorInfo[msg.sender].tokensBought - usedTokens(directorInfo[msg.sender].option);
    require(availableTokens >= votesInTokens);

    votesReceived[candidate] += votesInTokens;
    directorInfo[msg.sender].option[index] += votesInTokens;
  }

  function proposalList() view public returns (bytes32[]) {
    return register;
  }

  function usedTokens(uint[] _option) private pure returns (uint) {
    uint totalUsedTokens = 0;
    for(uint i = 0; i < _option.length; i++) {
      totalUsedTokens += _option[i];
    }
    return totalUsedTokens;
  }

  function details(address user) view public returns (uint, uint[]) {
    return (directorInfo[user].tokensBought, directorInfo[user].option);
  }

 function searchCandidate(bytes32 candidate) view public returns (uint) {
  for(uint i = 0; i < register.length; i++) {
   if (register[i] == candidate) {
    return i;
   }
  }
  revert();
 }

  //Función para retirar
  function cashOut() payable public onlyOwner() {
    owner.transfer(address(this).balance);
  }


}