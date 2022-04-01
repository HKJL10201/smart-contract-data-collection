pragma solidity ^0.4.11;


import "../lib/SafeMathLib.sol";
import "../ownership/Owned.sol";
import "../storage/TokenStorage.sol";


/**
 * This Token Contract implements the full ERC 20 Token standard
 * https://github.com/ethereum/EIPs/issues/20
 *
 * 1) Initial Finite Supply (upon creation one specifies how much is minted).
 * 2) In the absence of a token registry: Optional Decimal, Symbol & Name.
 * 3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.
 */
contract StandardToken is Owned, Modular {
  using SafeMathLib for uint;


  /**
   * Token version
   */
  string public version = '1.0.0';


  /**
   * Balances and spending allowances
   */
  TokenStorage public balances;


  /*
   * Token configuration parameters
   *
   * Decimals describe how the token base units will work. There could be
   * 1000 base units with 3 decimals. Meaning 0.980 LTRY = 980 base units.
   * It's like comparing 1 wei to 1 ether.
   */
  uint256 public totalSupply; // Total token supply
  string public name;         // Lottery
  string public symbol;       // LTRY
  uint8 public decimals;      // How many decimals to show


  /**
   * The token contract is not payable. If ether is sent to this address,
   * send it back.
   */
  function () {
    revert();
  }


  /**
   * Get the account balance of another account with address _owner
   *
   * @param _owner The address from which the balance will be retrieved
   * @return Balance of _owner
   */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances.get(_owner);
  }


  /**
   * Transfer tokens from message sender to given input address.
   * Default assumes totalSupply can't be over max (2^256 - 1).
   *
   * @notice send _value token to _to from msg.sender
   * @param _to The address of the recipient
   * @param _value The amount of token to be transferred
   * @return Whether the transfer was successful or not
   */
  function transfer(address _to, uint256 _value) returns (bool success) {
    require(balances.get(msg.sender) >= _value && balances.get(_to).plus(_value) > balances.get(_to));

    balances.decrease(msg.sender, _value);
    balances.increase(_to, _value);

    Transfer(msg.sender, _to, _value);
    return true;
  }


  /**
   * The transferFrom method is used for a withdraw workflow, allowing
   * contracts to send tokens on your behalf, for example to "deposit" to a
   * contract address and/or to charge fees in sub-currencies. The command
   * should fail unless the _from account has deliberately authorized the
   * sender of the message via some approval mechanism.
   *
   * @notice send _value token to _to from _from on the condition it is approved by _from
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value The amount of token to be transferred
   * @return Whether the transfer was successful or not
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(balances.get(_from) >= _value
      && balances.getAllowance(_from, msg.sender) >= _value
      && balances.get(_to).plus(_value) > balances.get(_to));

    balances.increase(_to, _value);
    balances.decrease(_from, _value);
    balances.decreaseAllowance(_from, msg.sender, _value);

    Transfer(_from, _to, _value);
    return true;
  }


  /**
   * Explicitly approve _spender to withdraw from your account, multiple
   * times, up to the _value amount. If this function is called again it
   * overwrites the current allowance with _value.
   *
   * @notice `msg.sender` approves `_spender` to spend `_value` tokens
   * @param _spender The address of the account able to transfer the tokens
   * @param _value The amount of tokens to be approved for transfer
   * @return Whether the approval was successful or not
   */
  function approve(address _spender, uint256 _value) returns (bool success) {
    balances.setAllowance(msg.sender, _spender, _value);

    Approval(msg.sender, _spender, _value);
    return true;
  }


  /**
   * Get the amount which _spender is still allowed to withdraw from _owner.
   *
   * @param _owner The address of the account owning tokens
   * @param _spender The address of the account able to spend the tokens
   * @return Allowance from _owner to _spender
   */
  function allowance(address _owner, address _spender) constant returns (uint256 _allowance) {
    return balances.getAllowance(_owner, _spender);
  }


  /**
   * Approves and then calls the receiving contract
   * Call the receiveApproval function on the contract you want to be notified.
   * This crafts the function signature manually so one doesn't have to include
   * a contract in here just for this.
   *
   * receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
   *
   * @param _spender The address of the account able to transfer the tokens
   * @param _value The amount of tokens to be approved for transfer
   * @param _extraData Any extra data that might be sent
   * @return Whether the approval was successful or not
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    balances.setAllowance(msg.sender, _spender, _value);
    Approval(msg.sender, _spender, _value);

    // It is assumed that when does this that the call *should* succeed,
    // otherwise one would use vanilla approve instead.
    require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
    return true;
  }


  /**
   * Interface declaration for defining this contract as a token contract
   *
   * @return The fact that this is a token contract
   */
  function isToken() constant returns (bool) {
    return true;
  }


  /**
   * Get the totalSupply from the token storage
   */
  function totalSupply() constant returns(uint256){
    return balances.getTotalSupply();
  }


  /*
   * Transfer and approval events
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
