//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract Payable5 {
    //PAYABLE keyword adds functionality of sending and receiving ether.

    address payable public owner; // This address can SEND ether.

    function deposit() external payable {} //This function can RECEIVE ether.

    //in constructor, I can't say owner=msg.sender because owner is payable and msg.sender is not yet.
    // So I cast msg.sender to payable
    constructor(){
      owner = payable(msg.sender);  
    }

    //This function returns the balance of the contract that includes this function. 
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }


}