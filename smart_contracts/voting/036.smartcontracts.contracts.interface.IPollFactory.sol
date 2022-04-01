pragma solidity ^0.4.15;

/**
    Copyright 2017, Konstantin Viktorov (XRED Foundation)
    Copyright 2017, Jordi Baylina (Giveth)
*/

contract IPollFactory {
  function create(bytes _description) returns(address);
}
