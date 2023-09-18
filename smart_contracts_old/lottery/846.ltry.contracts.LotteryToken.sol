pragma solidity ^0.4.11;


import "./lib/SafeMathLib.sol";
import "./token/MintableToken.sol";
import "./token/BurnableToken.sol";
/*
import "./token/UpgradeableToken.sol";*/


/*contract LotteryToken is UpgradeableToken, MintableToken, BurnableToken {*/
contract LotteryToken is MintableToken, BurnableToken {
  /**
   * LotteryToken
   */
  function LotteryToken(string _name, string _symbol, uint8 _decimals, address _tokenStorage) {
    name = _name;                                             // Set the name for display purposes
    symbol = _symbol;                                         // Set the symbol for display purposes
    decimals = _decimals;                                     // Amount of decimals for display purposes
    balances = TokenStorage(_tokenStorage);                   // Token storage reference
  }
}
