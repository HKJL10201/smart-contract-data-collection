pragma solidity ^0.4.24;

import "truffle/Assert.sol";

contract GenericTest {
  event LogInt(int n);
  event LogUint(uint n);
  event LogBool(bool b);
  
  function assertChangesBy(function() payable external returns (bool) action, function() view external returns (uint) check, int amount, string message) public {
    int beforeAmount = int(check());
    Assert.isTrue(action(), "The action failed");
    int afterAmount = int(check());
    
    int change;
    if(beforeAmount <= afterAmount) {      
      change = afterAmount - beforeAmount;
    } else {     
      change = 0 - (beforeAmount - afterAmount);
    }
    
    Assert.equal(amount, change, message);
  }
}
