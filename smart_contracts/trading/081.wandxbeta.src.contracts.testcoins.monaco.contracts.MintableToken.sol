pragma solidity ^0.4.8;
import "./StandardToken.sol";
import "./Ownable.sol";
import "./SafeMathLib.sol";

contract MintableToken is StandardToken, Ownable { 
  using SafeMathLib for uint; 
  bool public mintingFinished = false; 
  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents; 
  event MintingAgentChanged(address addr, bool state  );  
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = totalSupply.plus(amount);
    balances[receiver] = balances[receiver].plus(amount);
    Transfer(0, receiver, amount);
  } 
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  } 
  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  } 
  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }
}
