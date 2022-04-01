pragma solidity >=0.5.13;

import "./Allowance.sol";

contract FamilyWallet is Allowance {
 
  event MoneySent(address indexed _beneficiary, uint _amount);
  event MoneyReceived(address indexed _from, uint _amount); 
  
  function withdrawMoney( address payable _to, uint256 _amount) public 
    ownerOrAllowed(_amount)
  {
    require(_amount <= address(this).balance, "There are not enough funds in contract");

    if(owner() != msg.sender) {
      reduceAllowance(msg.sender, _amount);
    }
    emit MoneySent(_to, _amount);
    _to.transfer(_amount);
  }

  function renounceOwnership() public override onlyOwner {
    revert("Can't renounce ownership");
  }

  fallback () external payable {
    emit MoneyReceived(msg.sender, msg.value); 
  }
}
