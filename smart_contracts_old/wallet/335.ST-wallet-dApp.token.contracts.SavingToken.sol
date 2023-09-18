/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/


pragma solidity ^0.4.18;

import "./ERC20Modified.sol";
import "./SafeMath.sol";

contract SavingToken is ERC20Modified {
  using SafeMath for uint;

  string public name;
  string public symbol;
  address public owner;
  uint256 public totalSupply;
  uint256 constant private MAX_UINT256 = 2**256 - 1;
  mapping (address => uint256) public balances;
  mapping (address => uint256) public nextTxTime;
  mapping (address => uint256) public lockTime;
  mapping (address => mapping(address => uint256)) allowedAddress;

  function SavingToken (uint256 _totalSupply) public {
    owner = msg.sender;
    name = "SavingToken";
    symbol = "ST";
    totalSupply = _totalSupply;
    balances[owner] = _totalSupply;
  }

  function getTime() public view returns (uint time) {
    return now;
  }

  function transferOwner (address newOwner) public {
    require(msg.sender == owner);
    owner = newOwner;
  }

  function balanceOf(address _address) public view returns (uint256) {
    return balances[_address];
  }

  function transfer (address _to, uint256 _value) public returns (bool success) {
    uint256 accountBalance = balances[msg.sender];
    uint256 currentTime = now;
    if (_value > 0 && accountBalance > 0 && _value <= accountBalance && (nextTxTime[msg.sender] < currentTime)) {
      balances[_to] = balances[_to].add(_value);
      balances[msg.sender] = accountBalance.sub(_value);
      nextTxTime[msg.sender] = now + (lockTime[msg.sender] * 60);
      Transfer(msg.sender, _to, _value, success=true);
      return true;
    }
    Transfer(msg.sender, _to, _value, success=false);
  return false;
  }

  function changeLockTime(uint8 newLockTime) public {
    lockTime[msg.sender] = newLockTime;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(msg.sender != _spender);
    allowedAddress[msg.sender][_spender] = _value;
     Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    uint256 allowedBalance = allowedAddress[_from][msg.sender];
    require(_value <= allowedBalance && _value <= balances[_from]);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    if (allowedBalance < MAX_UINT256) {
      allowedAddress[_from][msg.sender] -= _value;
    }

     TransferFrom(_from, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowedAddress[_owner][_spender];
  }
}
