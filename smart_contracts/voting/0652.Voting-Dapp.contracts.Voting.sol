pragma solidity ^0.4.18;
// Tenemos que especificar qué versión del compilador compilará este código

contract Voting {

 /* El siguiente campo de mapeo es equivalente a una matriz asociativa o hash.
 La clave de la asignación es el nombre candidato almacenado como tipo bytes32 y
  el valor  es un entero sin signo para almacenar el conteo de votos  */
  mapping (bytes32 => uint8) public votesReceived;

  /* Solidity no le permite pasar una serie de cadenas en el constructor (todavía).
 Utilizaremos una matriz de bytes32 para almacenar la lista de candidatos */
  bytes32[] public candidateList;

 /* Este es el constructor que se llamará una vez cuando se
 implemente el contrato a la cadena de bloques. Cuando desplegamos el contrato,
 pasaremos una serie de candidatos que competirán en las elecciones */
 function Voting(bytes32[] candidateNames) public {
   candidateList = candidateNames;
 }

 // Esta función devuelve el total de votos que un candidato ha recibido hasta ahora
 function totalVotesFor(bytes32 candidate) view public returns (uint8) {
   require(validCandidate(candidate));
   return votesReceived[candidate];
 }

 // Esta función incrementa el conteo de votos para el candidato especificado.
 // Esta es equivalente a emitir un voto
 function voteForCandidate(bytes32 candidate) public {
   require(validCandidate(candidate));
   votesReceived[candidate] += 1;
 }

 function validCandidate(bytes32 candidate) view public returns (bool) {
   for (uint i = 0; i < candidateList.length; i++) {
     if (candidateList[i] == candidate) {
       return true;
     }
   }
   return false;
 }
}