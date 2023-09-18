pragma solidity ^0.4.11;


import "../token/StandardToken.sol";

/**
 * @title DALToken
 * @author Master-S
 */
contract DALToken is StandardToken {

  string public constant NAME = "leagiON Token";
  string public constant SYMBOL = "DAL";
  uint8 public constant DECIMALS = 18;

  uint256 public constant INITIAL_SUPPLY = 100000000 * 10**18;

  event DALTokenCreated(address owner, uint256 tokenUnits);
  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function DALToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    DALTokenCreated(msg.sender, balanceOf(msg.sender));
  }

}
