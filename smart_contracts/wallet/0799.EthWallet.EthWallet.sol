// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SmartContractWallet {

   address payable public owner;

   constructor () {
     owner = payable (msg.sender);
   }

   receive() external payable {}

   function withdraw (uint ammount) public {
     require ( owner == msg.sender, "You Are Not Owner");
     payable(msg.sender).transfer(ammount);
   }

   function getBalance() public view returns(uint256){
     return address(this).balance;
   }

}
