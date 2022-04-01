pragma solidity >=0.5.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
  using SafeMath for uint256;

  event AllowanceChanged(address _forWho, address _fromWhom, uint _oldAmount, uint _newAmount);
  
  mapping(address => uint) public allowance;
 
  modifier ownerOrAllowed(uint _amount) {
    require(owner() == msg.sender || allowance[msg.sender] >= _amount, "You are not allowed");
    _;
  }

  function addAllowance(address _who, uint _amount) public 
    onlyOwner 
  {
    emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
    allowance[_who] = _amount;
  }

  function reduceAllowance(address _who, uint _amount) internal ownerOrAllowed(_amount) {
    emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
    allowance[_who] = allowance[_who].sub(_amount); 
  }
}
