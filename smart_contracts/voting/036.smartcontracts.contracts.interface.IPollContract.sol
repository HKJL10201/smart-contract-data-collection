pragma solidity ^0.4.15;

/**
    Copyright 2017, Konstantin Viktorov (XRED Foundation)
    Copyright 2017, Jordi Baylina (Giveth)
*/

contract IPollContract {
  function deltaVote(int _amount, bytes32 _ballot) returns (bool _succes);
  function pollType() constant returns (bytes32);
  function question() constant returns (string);
}
