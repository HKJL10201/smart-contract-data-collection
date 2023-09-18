// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Lottery {
    address public manager;
    address payable[] public participants;
   
    

    constructor(){
        manager = msg.sender;
       
    } 

    receive() external payable{
        require(msg.value == 1 ether, "Please deposit 1 Ethers.");
        participants.push(payable(msg.sender));
    }

    modifier onlyManager(){
       require(manager == msg.sender, "You are not the manager");
     
       _; 
    }

    function getBalance() public view onlyManager returns(uint){
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    function Winner1() public onlyManager {
         require(participants.length>=5);
        uint amount = getBalance();
        uint first = random();
        address payable winner1;
        uint index1 = first % participants.length;
        winner1 = participants[index1];
        winner1.transfer(amount * 6/10);
        getBalance();
    }

    function Winner2() public onlyManager {
       require(participants.length>=5);
       uint amount = getBalance();
       uint second = random();
       address payable winner2;
       uint index2 = second % participants.length;
       winner2 = participants[index2];
       winner2.transfer(amount);
       getBalance();
       
    }

     function newLottery() public {
      participants = new address payable[](0);
     }
}