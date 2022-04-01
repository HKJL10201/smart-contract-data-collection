pragma solidity ^0.4.4;
contract helloWorld  {

    address public owner;
    mapping(address => uint) balances;

    function helloWorld() {
        owner = msg.sender;
        balances[owner] = 1000;
    }

    function transfer(address _user, uint _value) returns(bool success) {
      if(balances[msg.sender] < _value) {
        return false;
      }

      balances[msg.sender] -= _value;
      balances[_user] += _value;

      return true;

    }

    function getBalance(address _user) constant returns(uint _balance) {
        return balances[_user];
    }
}
