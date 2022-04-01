// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherWallet {

  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  function deposit() payable external{}

  function send(address payable _to, uint _amount) external{
    require(msg.sender == owner, 'Only Owner can end');
    _to.transfer(_amount);
  }

  function balanceOf() external view returns(uint){
    return address(this).balance;
  }

}
