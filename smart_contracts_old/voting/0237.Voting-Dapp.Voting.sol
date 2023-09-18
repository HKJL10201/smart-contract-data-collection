/*
  This Smart Contract is based off of:
    https://medium.com/@mvmurthy/full-stack-hello-world-voting-ethereum-dapp-tutorial-part-1-40d2d0d807c2?ref=dappnews
  More informaiton on how to read the Smart Contract here:
    https://solidity.readthedocs.io/en/develop/introduction-to-smart-contracts.html#subcurrency-example

  Precursory notes:

  - The keyword public specifies auto-generation of a function that allows access to state variables
    from outside (i.e. the Blockchain) the context of the Smart Contract

  - Functions marked with 'view' promise the compiler they do not modify state variables (i.e. storage),
    Modification of state variables requires verification by the network, and consequently verification
    is achieved through mining, which requires gas.
    (As opposed to 'pure' functions, which promise not to modify OR READ the state)
*/

// Specifies the version of Solidity this contract was written in (intended for the compiler)
pragma solidity ^0.4.18;

contract Voting {
  /*
    The mapping below creates an associative array of a dynamic 32-byte array to an 8-bit integer value.
    This 8-bit value represents the amount of votes each address has received.
  */
  mapping (bytes32 => uint8) public votesReceived;


  /*
    The state variable candidateList, which as its name implies, is a list/array of all votable
    addresses.
  */
  bytes32[] public candidateList;

  /*
    The constructor can only be called once when it is deployed to the blockchain.
    'candidateNames' is an array of candidates/addresses that are votable
  */
  constructor(bytes32[] candidateNames) public {
    candidateList = candidateNames;
  }

  /*
    Check the total votes a candidate has recieved
  */
  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  /*
    Vote for a candidate
  */
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  /*
    Check if an candidate is valid
  */
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++){
      if(candidateList[i] == candidate) return true;
    }
    return false;
  }
}
