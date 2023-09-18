pragma solidity 0.5.8;

import "./MinimalVotingZoKratesVerifier.sol";

contract MinimalVotingWithZoKrates {
  Verifier public verifier;

  mapping(uint256 => uint256) public votes;

  constructor(Verifier _verifier) public {
  	verifier = _verifier;
  }

  function vote(uint256 _number, uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[1] memory input) public {
  	require(verifier.verifyTx(a, b, c, input));
    votes[_number]++;
  }
}