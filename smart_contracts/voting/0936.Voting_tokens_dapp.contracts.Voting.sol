pragma solidity ^0.4.18; 

contract Voting {

  // Voter almacena la address del votante,los tokens que ha comprado y sus votos por candidato
  struct Voter {
    address voterAddress;
    uint tokensBought;
    uint[] tokensUsedPerCandidate;
   }

  //Para obtener info de votos por address
   mapping (address => Voter) public voterInfo;

   mapping (bytes32 => uint) public votesReceived;

   bytes32[] public candidateList;

  //Total de tokens emitidos, total restante y el precio de cada token
   uint public totalTokens; 
   uint public balanceTokens;
   uint public tokenPrice;
   address owner;

 
  //Constructor: recibe listado de candidatos, cantidad de tokens a emitir, el balance y el precio del token. 
  function Voting(uint tokens, uint pricePerToken, bytes32[] candidateNames) public {
    candidateList = candidateNames;
    totalTokens = tokens;
    balanceTokens = tokens;
    tokenPrice = pricePerToken;
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
   }

  //Función que permite comprar tokens con ethers. 
  function buy() payable public returns (uint) {
    uint tokensToBuy = msg.value / tokenPrice; //Cantidad de token a comprar 
    require(tokensToBuy <= balanceTokens); // Verifica que sea menos de lo que tiene el balance
    voterInfo[msg.sender].voterAddress = msg.sender; 
    voterInfo[msg.sender].tokensBought += tokensToBuy; 
    balanceTokens -= tokensToBuy;
    return tokensToBuy;
  }

  function totalVotesFor(bytes32 candidate) view public returns (uint) {
    return votesReceived[candidate];
  }

  /* Incrementamos el conteo de votos de los candidatos, hacemos un seguimiento de la información del votante, 
  como quién era el votante (la dirección de su cuenta), cuántos votos emitidos y a qué candidato.*/
  function voteForCandidate(bytes32 candidate, uint votesInTokens) public {
    uint index = indexOfCandidate(candidate);
    require(index != uint(-1));

    if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
     for (uint i = 0; i < candidateList.length; i++) {
      voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
    }
  }

  uint availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
  require (availableTokens >= votesInTokens);

  votesReceived[candidate] += votesInTokens;
  voterInfo[msg.sender].tokensUsedPerCandidate[index] += votesInTokens;
  }

 function totalTokensUsed(uint[] _tokensUsedPerCandidate) private pure returns (uint) {
  uint totalUsedTokens = 0;
  for (uint i = 0; i < _tokensUsedPerCandidate.length; i++) {
   totalUsedTokens += _tokensUsedPerCandidate[i];
  }
  return totalUsedTokens;
 }

 function indexOfCandidate(bytes32 candidate) view public returns (uint) {
  for (uint i = 0; i < candidateList.length; i++) {
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

 //Función que permite transferir los ethers
 function transferTo(address account) onlyOwner {
  account.transfer(this.balance);
 }

 function allCandidates() view public returns (bytes32[]) {
  return candidateList;
 }
}