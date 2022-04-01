pragma solidity 0.5.16;

contract Election {
  string public candidate;

  constructor() public {
    candidate = 'candidate 1';
  }
}