pragma solidity ^0.4.11;


import "../lib/SafeMathLib.sol";
import "./StandardToken.sol";


/**
 * A token that can decrease its supply through another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 */
contract BurnableToken is StandardToken {
  using SafeMathLib for uint;


  /**
   * Determine whether the token can be burned or not
   */
  bool public burnable = true;


  /**
   * Remove _value tokens from the system, irreversibly
   *
   * @param _value the amount of money to burn
   */
  function burn(uint256 _value) canBurn returns (bool success) {
    require(balances.get(msg.sender) > _value);     // Check if the sender has enough
    balances.decrease(msg.sender, _value);          // Subtract from the sender
    balances.decreaseTotalSupply(_value);           // Updates totalSupply
    Burn(msg.sender, _value);
    return true;
  }


  // Remove _value tokens from the _from address, irreversibly
  //
  // @param _from The address of the account owning tokens
  // @param _value the amount of money to burn
  //
  function burnFrom(address _from, uint256 _value) canBurn returns (bool success) {
    require(balances.get(_from) >= _value);                       // Check if the targeted balance is enough
    require(_value <= balances.getAllowance(_from, msg.sender));   // Check allowance
    balances.decrease(_from, _value);                             // Subtract from the targeted balance
    balances.decreaseAllowance(_from, msg.sender, _value);        // Subtract from the sender's allowance
    balances.decreaseTotalSupply(_value);                         // Update totalSupply
    Burn(_from, _value);
    return true;
  }


  /**
   * Stop burning any tokens.
   *
   * @return True if the operation was successful.
   */
  function setBurnable(bool _burnable) onlyOwner returns (bool _finished) {
    burnable = _burnable;

    BurningStatusChanged();
    return true;
  }


  /**
   * Determine whether tokens can be burned
   */
  modifier canBurn() {
    require(burnable);
    _;
  }


  // Burn events
  //
  event Burn(address indexed _from, uint indexed _amount);
  event BurningStatusChanged();
}
