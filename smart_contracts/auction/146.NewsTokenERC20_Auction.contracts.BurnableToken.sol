pragma solidity ^0.4.18;

import "./StandardToken.sol";

contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);
 
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]); 

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}
