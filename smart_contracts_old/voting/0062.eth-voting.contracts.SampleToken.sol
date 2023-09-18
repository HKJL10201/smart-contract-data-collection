pragma solidity ^0.4.16;

contract StdToken {
     function transfer(address, uint256) returns(bool);
     function transferFrom(address, address, uint256) returns(bool);
     function balanceOf(address) constant returns (uint256);
     function approve(address, uint256) returns (bool);
     function allowance(address, address) constant returns (uint256);
}

contract SampleToken is StdToken {
// Fields:
     string public constant name = "Goldmint Sample Token";
     string public constant symbol = "GMST";
     uint public constant decimals = 18;

     address public creator = 0x0;

// For tests:
     mapping(address => uint256) testBalances;
     function issueTokens(address _for, uint _amount) public {
          testBalances[_for] = _amount;
     }

     function SampleToken() {
          creator = msg.sender;
     }

     function transfer(address, uint256) returns(bool){
          return false;
     }

     function transferFrom(address, address, uint256) returns(bool){
          return false;
     }

     function balanceOf(address _a) constant returns (uint256){
          return testBalances[_a];
     }

     function approve(address, uint256) returns (bool){
          return false;
     }

     function allowance(address, address) constant returns (uint256){
          return 0;
     }
}
