// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Decentralized_Lottery_Application
{

// Always remember payable keyword is used for the address/contract receiving the ether not the address/contract sending the ether.

    address public manager ;
    address payable[] public participants;
    // we can only use one contructor at max and we use to when we deploy the contract
    constructor()
    {
       manager = msg.sender;
    }
    // This contract receives ether from some other smart contract and thats why its payable since it is receiveing ether from some other address;
     function receive() external payable
    {
        require(msg.value == 1 ether , "You need to send exactly 1 ether to the contact for lottery eligibilty");
        participants.push(payable(msg.sender));
    }
    // Get the balance of the contract 
    function getbalance() public view returns(uint)
    {
       require(msg.sender == manager,"Only the lottery manager can check the balance of the particular smart contract"); 
       return address(this).balance; // Balance of the smart contract
    }
   // This function helps in generating random value
    function random() public view returns(uint)
    {
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length))); // first converting byte32 into uint and returning some random value
    }
  // Selecting winner from the Lottery by only the manager and sends ether to the particular winner and thats why winner is defined as payable
    function selectWinner() public 
    {
       require(participants.length>=3,"Participants should be greater than or equal to 3");
       uint r = random();
       address payable winner;
       uint index = r % participants.length;
       winner = participants[index];
       winner.transfer(getbalance());
       participants = new address payable[](0); // The contract will reset once the round has finished 
    }

 


}
