pragma solidity ^0.4.11;


import "../lib/SafeMathLib.sol";
import "../ownership/Owned.sol";
import "../ownership/Modular.sol";


/**
 * Abstract user balances away from the token's business logic, making the
 * tokens upgradeable, and open for modular functionality to be added over time.
 */
contract TokenStorage is Owned, Modular {
  using SafeMathLib for uint;


  /**
   * Total token supply
   */
  uint256 public totalSupply;


  /**
   * Token balances, modules and allowances
   */
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) allowed;


  /**
   * TokenStorage constructor
   *
   * @param _totalSupply Total supply of tokens
   */
  function TokenStorage(uint256 _totalSupply) {
    totalSupply = _totalSupply;
    balances[msg.sender] = _totalSupply; // Give the creator all initial tokens
  }


  /**
   * The token storage contract is not payable. If ether is sent to this
   * address, send it back.
   */
  function () {
    revert();
  }


  /**
   * Get the account balance of another account with address _owner.
   *
   * @param _owner The address from which the balance will be retrieved
   * @return Balance of _owner
   */
  function get(address _owner) constant returns (uint256 _balance){
    return balances[_owner];
  }


  /**
   * Increase the balance of _owner by _value tokens.
   *
   * @param _owner The address of the person whose balance increases
   * @param  _value The value by which the balance increases
   *
   */
  function increase(address _owner, uint256 _value) onlyModule returns (bool _success) {
    balances[_owner] = balances[_owner].plus(_value);
    BalanceAdjustment(msg.sender, _owner, _value, "+");
    return true;
  }


  /**
   * Decrease the balance of _owner by _value tokens.
   *
   * @param _owner The address of the person whose balance decreases
   * @param  _value The value by which the balance decreases
   *
   */
  function decrease(address _owner, uint256 _value) onlyModule returns (bool _success) {
    balances[_owner] = balances[_owner].minus(_value);
    BalanceAdjustment(msg.sender, _owner, _value, "-");
    return true;
  }


  /**
   * Get the total supply of tokens.
   */
  function getTotalSupply() constant returns (uint256) {
    return totalSupply;
  }


  /**
   * Increase the total supply of tokens by _value.
   *
   * @param _value Amount of tokens added to the total supply
   */
  function increaseTotalSupply(uint256 _value) onlyModule returns (bool _success) {
    totalSupply = totalSupply.plus(_value);
    return true;
  }


  /**
   * Decrease the total supply of tokens by _value.
   *
   * @param _value Amount of tokens removed from the total supply
   */
  function decreaseTotalSupply(uint256 _value) onlyModule returns (bool _success) {
    totalSupply = totalSupply.minus(_value);
    return true;
  }


  /**
   * Get the amount which _spender is still allowed to withdraw from _owner.
   *
   * @param _owner The address of the account owning tokens
   * @param _spender The address of the account able to transfer the tokens
   * @return Amount of remaining tokens allowed to spent
   */
  function getAllowance(address _owner, address _spender) constant returns (uint256 _remaining) {
    return allowed[_owner][_spender];
  }


  /**
   * Set the amount which _spender is still allowed to withdraw from _owner.
   *
   * @param _owner The address of the account owning tokens
   * @param _spender The address of the account able to transfer the tokens
   */
  function setAllowance(address _owner, address _spender, uint256 _value) onlyModule returns (bool _success) {
    allowed[_owner][_spender] = _value;
    return true;
  }


  /**
   * Decrease the amount which _spender is still allowed to withdraw from _owner
   * by _value tokens.
   *
   * @param _owner The address of the account owning tokens
   * @param _spender The address of the account able to transfer the tokens
   */
  function decreaseAllowance(address _owner, address _spender, uint _value) onlyModule returns (bool _success) {
    allowed[_owner][_spender] = allowed[_owner][_spender].minus(_value);
    return true;
  }


  /**
   * Increase the amount which _spender is still allowed to withdraw from _owner
   * by _value tokens.
   *
   * @param _owner The address of the account owning tokens
   * @param _spender The address of the account able to transfer the tokens
   */
  function increaseAllowance(address _owner, address _spender, uint _value) onlyModule returns (bool _success) {
    allowed[_owner][_spender] = allowed[_owner][_spender].plus(_value);
    return true;
  }


  /**
   * Balance adjustment and module change events
   */
  event BalanceAdjustment(address indexed _module, address indexed _owner, uint _amount, string _polarity);
}
