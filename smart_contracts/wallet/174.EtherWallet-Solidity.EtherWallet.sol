// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

//Billetera de ether
contract EtherWallet{

          //Dirección del propietario
          address public owner;

          //Constructor del smart contract
          constructor(address _owner) {
              owner = _owner;
          }

          //Función depositar dinero
          function deposit() payable public{
          }  


          //Función enviar dinero
          function send(address payable to, uint amount)public{
            if(msg.sender==owner){
              to.transfer(amount);
              return;
            }
            revert("Sender is not allowed");
          }

          //Función obtener el balance de la billetera
          function balanceOf() view public returns(uint){
              return address(this).balance;
          }





}