// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 < 0.9.0;
// Code Eater Lottery Project
// https://youtu.be/aFI_XPll_mg
contract lottery{
    address public manager;
    address payable[] public participants;
    constructor(){
        manager=msg.sender;
    }
    receive() external payable{
       require( msg.value==1 ether, "Please send 1 Ether");
       participants.push(payable(msg.sender));
    }function getBalance() public view returns(uint){
        require(msg.sender==manager,"You are not a manager");
        return address(this).balance;
    }
    function random() public view returns(uint) {
return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp)));
    }
    function selectWinner() public {
        require(msg.sender==manager,"You are not a manager");
        require(participants.length>=3);
        uint r=random();
        uint num= r % participants.length;
        address payable winner;
        winner = participants[num];
        winner.transfer(getBalance());
        participants=new address payable[](0); 
        // The above line deletes all the participants from the array after declaring the winner.

    }
   
}