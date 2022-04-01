pragma solidity ^0.4.18;
 
import "./StandardToken.sol";
import "./BurnableToken.sol";

contract NewsToken is BurnableToken {

  string public constant name = "NewsToken";  
  string public constant symbol = "NEWS"; 
  uint8 public constant decimals = 12;  

  uint256 public constant INITIAL_SUPPLY = 175000000 * (10 ** uint256(decimals));

  address bountyWallet = 0x0; 
 
  function NewsToken(address saleAgent) public {
    totalSupply_ = INITIAL_SUPPLY;

    balances[bountyWallet] = 15000000 * (10 ** uint256(decimals));
    Transfer(0x0, bountyWallet, 15000000 * (10 ** uint256(decimals)));
    
    balances[saleAgent] = INITIAL_SUPPLY - balances[bountyWallet];
    Transfer(0x0, saleAgent, INITIAL_SUPPLY - balances[bountyWallet]); 
  }  

  function transferBountyTokens(address[] _recivers, uint[] _amountTokens) public returns(bool) {
      require(bountyWallet == msg.sender);
      require(_recivers.length == _amountTokens.length);
      require(_recivers.length <= 40);
        
    for(uint i = 0; i < _recivers.length; i++) { 
        balances[bountyWallet] = balances[bountyWallet].sub(_amountTokens[i]);
        balances[_recivers[i]] = balances[_recivers[i]].add(_amountTokens[i]);

        Transfer(bountyWallet, _recivers[i], _amountTokens[i]); 
    }
  }
} 

