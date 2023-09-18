pragma solidity ^0.6.4;
// Version con la que se compilará

contract Voting {
  /* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */
  mapping (bytes32 => uint256) public votesReceived;
  
  // En solidity se debe usar bytes32 para el almacen de data
  bytes32[] public candidateList;

  // Constructor que se llamará al subir el contrato al blockchain
  constructor(bytes32[] memory candidateNames) public {
    candidateList = candidateNames;
  }

  // Funcionalidad para mostrar los votos de un candidato
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // funcionalidad para dar un boto
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  // Funcion para validar el candidato
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}