pragma solidity >=0.4.21; 
//Declaremos la versión del compilador de Solidity. 

 //Declaramos el smart contract. 
contract Voting {

address payable internal voting_owner;

  //Estructura que define las características del votante
  struct voter {
    address voterAddress; //Dirección del votante
    uint tokensBought;    //Número total de tokens que ha comprado el votante
    uint[] tokensUsedPerCandidate; //Array para realizar el seguimiento de los votos a los candidatos
  }

  mapping (address => voter) public voterInfo; //Mapping relaciona una dirección con un votante (voter)

  mapping (bytes32 => uint) public votesReceived; //Mapping que realaciona los candidatos con los votos recibidos

  bytes32[] public candidateList; //Array con los candidatos

  uint public totalTokens; //Número total de tokens disponibles para las votaciones
  uint public balanceTokens; //Número de tokens disponibles para ser comprados
  uint public tokenPrice; //Precio del token


   modifier only_owner(){ //Hacer el contrato "ownable" donde el propuetario del contrato tiene ciertos privilegios.
	        require(msg.sender == voting_owner, "No eres el dueño del smart contract");
	        _;
	    }


  //Constructor que se inicia cuando se desplega el smart contract
  constructor (uint tokens, uint pricePerToken, bytes32[] memory candidateNames) public {
    candidateList = candidateNames;
    totalTokens = tokens;
    balanceTokens = tokens;
    tokenPrice = pricePerToken;
    voting_owner = msg.sender;
  }

   //Comprar tokens. Intercambio de ether por tokens para poder votar
  function buy() public payable returns (uint) {
    uint tokensToBuy = msg.value / tokenPrice;
    require(tokensToBuy <= balanceTokens, "No hay suficients tokens para comprar");
    voterInfo[msg.sender].voterAddress = msg.sender;
    voterInfo[msg.sender].tokensBought += tokensToBuy;
    balanceTokens -= tokensToBuy;
    return tokensToBuy;
  }


  //Votar por un candidato
  function voteForCandidate(bytes32 candidate, uint votesInTokens) public {
    uint index = indexOfCandidate(candidate);
    require(index != uint(-1), "El candidato no existe");

    if (voterInfo[msg.sender].tokensUsedPerCandidate.length == 0) {
      for(uint i = 0; i < candidateList.length; i++) {
        voterInfo[msg.sender].tokensUsedPerCandidate.push(0);
      }
    }

    //Comprobamos que el votante tiene suficientes tokens
    uint availableTokens = voterInfo[msg.sender].tokensBought - totalTokensUsed(voterInfo[msg.sender].tokensUsedPerCandidate);
    require(availableTokens >= votesInTokens, "El votante no tiene suficientes tokens");

    votesReceived[candidate] += votesInTokens;

    //Guardamos cuantos tokens se han usado para ese candidato
    voterInfo[msg.sender].tokensUsedPerCandidate[index] += votesInTokens;
  }

  //Comprobamos el total de tokenes usado para ese candidato
  function totalTokensUsed(uint[] memory _tokensUsedPerCandidate) private pure returns (uint) {
    uint totalUsedTokens = 0;
    for(uint i = 0; i < _tokensUsedPerCandidate.length; i++) {
      totalUsedTokens += _tokensUsedPerCandidate[i];
    }
    return totalUsedTokens;
  }

 //Comprobar el índice del candidato en la lista de candidatos
  function indexOfCandidate(bytes32 candidate) public view returns (uint) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return i;
      }
    }
    return uint(-1);
  }

  
 //Comprobar cuantos votos tienen un candidato
  function totalVotesFor(bytes32 candidate) public view returns (uint) {
    return votesReceived[candidate];
  }

 //Comprobar cuantos tokens se han vendido
  function tokensSold() public view returns (uint) {
    return totalTokens - balanceTokens;
  }


  //Consultar información sobre un votante.
  function voterDetails(address user) public view returns (uint, uint[] memory) {
    return (voterInfo[user].tokensBought, voterInfo[user].tokensUsedPerCandidate);
  }


  //Enviar el ether recaudado de la votación a una dirección. Solo el propietario puede ejecutar esta función
  function transferTo(address payable account) public only_owner {
    account.transfer(address(this).balance);
  }


  //Consultar la lista de candidatos
  function allCandidates() public view  returns (bytes32[] memory) {
    return candidateList;
  }

  //Consultar el propietario del contrato
  function get_owner() public view returns(address){
            return voting_owner;
        }


   //Consultar balance smart contract
  function check_balance() public view returns(uint){
            return address(this).balance;
        }

}