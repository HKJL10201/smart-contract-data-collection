

//jshint ignore: start

pragma solidity ^0.4.11;

import './Ownable.sol';
import './Don.sol';

contract Donatti is Ownable {
  
  address[] public dons;
  mapping(address => uint256[]) public donMap;
  
  function() payable {}
  
  //new don
  function create(string _name, bool _open, bool _over, uint256 _start, uint256 _end, uint256 _goal, string _url) payable {
    Don don = new Don(this);
    don.update(_name, _open, _over, _start, _end, _goal, _url);
    don.transferOwnership(msg.sender);
    donMap[msg.sender].push(dons.length);
    dons.push(don);
  }
  
  //get dons
  function getDons() returns (address[], uint256[]) {
    uint256[] storage list = donMap[msg.sender];
    address[] memory addr = new address[](list.length);
    for (uint i = 0; i < list.length; i++) {
      addr[i] = dons[list[i]];
    }
    return (addr, list);
  }
  
  //cannot return entire address array, must address dons seperately
  function totalDons() constant returns(uint256) {
    return dons.length;
  }
  
  /**************************************
  * Token Functionality
  **************************************/
  
  string public name = 'Donatti Token';
  string public symbol = 'DONT';
  uint256 public decimals = 18;
  
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  
  function credit(address _to, uint256 _amount) {
    balanceOf[_to] += _amount;
    totalSupply += _amount;
  }
  
  function transfer(address recipient, uint amount) {
    
  }
  
}

//jshint ignore: end