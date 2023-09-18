pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract Callee {

  uint foo = 2;

  function setFoo(uint v) public {
    foo = v;
  }

  function getFoo() view public returns (uint) {
      return foo;
  }

}

contract Caller {

  function makeACall(address calleeAddr, uint fooVal) public {
    Callee callee = Callee(calleeAddr);
    callee.setFoo(fooVal);
  }

}
