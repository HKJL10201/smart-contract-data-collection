// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract EscroWallet {
  address public payer;
  address payable public payee;
  address public lawyer;
  uint public amount;

  constructor(address _payer, address payable _payee, uint _amount) {
    lawyer = msg.sender;
    payer = _payer;
    payee = _payee;
    amount = _amount;
  }

  function deposit() payable external {
    require(msg.sender == payer, 'only payer can deposit ether');
    require(msg.value <= amount, 'Can not send more than Escrow Amount');
  }

  function release() external {
    require(msg.sender == lawyer, 'only lawyer can release the funds');
    require(address(this).balance >= amount, 'can not release funds if full amount not received');
    payee.transfer(amount);
  }

  function balanceOf() external view returns(uint) {
    return (address(this).balance);
  }
  
}
