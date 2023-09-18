//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9


contract ERCToken { 
uint256 TOTAL_SUPPLY =1000;
mapping address => uint256 ;_balance
mapping address => mapping (address => uint) _allowance;
mapping address => mapping (address => bool) _approval;

event Transfer (address indexed _from, address indexed _to, uint256 _value)
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
function name () public pure returns (string memory){ return "Web3 Bootcamp"; }
 function symbol () public pure returns (string memory) { return "W3BC"; }
 function decimal () public view returns (uint8) { return 2 ;}
 function totalSupply () public view returns (uint256){ return TOTAL_SUPPLY;}
  function balanceOf(address _owner) public view returns (uint256 
  
  return _balance [_owner];}
  function transfer(address _to, uint256 _value) public returns (bool success){
  // check
  require _balance[msg.sender] >= _value;
  //decrease caller
  _balance[msg.sender] -= _value;
  //increase recepient
  _balance[_to] += _value
  //balance transfer event
  emit Transfer(msg.sender, _to, _value);
  //return success
  return true ;}
  
  
   function approve(address _spender, uint256 _value) public returns (bool success){
// emit 
emit event Approval(address indexed _owner, address indexed _spender, uint256 _value)
//set spender allowance
  _allowance[msg. sender][_spender] = _value;
//return success
return true }
function allowance(address _owner, address _spender) public view returns (uint256 remaining){ return _allowance[_owner][_spender]; }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){ 
 //check is sender is approved
require (_allowance[_from][msg.sender] >= value, "Insufficient allowance");
//check enough balance
require (_balance[_from] >= _value, "Insufficient balance");
// decrease from balance
_balance[_from] -= _value;
// increase to balance
_balance[_to] += _value;
//decrease spender allowance
_allowance[_from][_msg.sender] -= _value;
//emit transfer event
emit Transfer (_from, _to, _value);

//return success
return true ;}



}
