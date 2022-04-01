pragma solidity ^0.4.11;


import "../lib/SafeMathLib.sol";
import "./StandardToken.sol";


/**
 * A token that can increase its supply through another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 */
contract MintableToken is StandardToken {
  using SafeMathLib for uint;


  /**
   * Determine whether the token can be minted or not
   */
  bool public mintable = true;


  /**
   * Returns the amount which _spender is still allowed to withdraw from _owner
   *
   * @param _to The address of the account to reveive the tokens
   * @param _amount The amount of tokens to be minted
   * @return Amount of remaining tokens allowed to spent
   */
  function mint(address _to, uint256 _amount) onlyModule canMint public returns (bool _minted) {
    balances.increaseTotalSupply(_amount);
    balances.increase(_to, _amount);

    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);

    return true;
  }


  /**
   * Stop minting new tokens.
   *
   * @return True if the operation was successful.
   */
  function setMintable(bool _mintable) onlyOwner returns (bool _finished) {
    mintable = _mintable;

    MintingStatusChanged();
    return true;
  }


  /**
   * Determine whether new tokens can be minted
   */
  modifier canMint() {
    require(mintable);
    _;
  }


  event Mint(address indexed _to, uint256 _amount);
  event MintingStatusChanged();
}
