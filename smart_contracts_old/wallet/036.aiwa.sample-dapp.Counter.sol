/*
  sol Counter
  Simple Counter Contract - Increase / Decrease by 1
*/

pragma solidity ^0.4.10;

contract Counter {

  
  int private count;

  /* Functions */
  // Functions are the executable units of code within a contract.
  function Counter(int _initCount) public {
      count = _initCount;
  }

  function incrementCounter() public {
      count += 1;
  }
  function decrementCounter() public {
      count -= 1;
  }
  function getCount() public constant returns (int) {
      return count;
  }

  function pay() public payable {
      
  }
}
