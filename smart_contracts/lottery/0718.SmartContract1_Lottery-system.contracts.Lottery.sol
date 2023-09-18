// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery
{
    address public  manager;
    address payable[] public participants;

    constructor()   //initalize manager address
    {   
        manager=msg.sender;
    }

    receive() external payable //payable makes payable
    {
        require(msg.value==1 ether); //if less than 1 ether no exicution 
        participants.push(payable(msg.sender));  //adds in participants address
    }

    function getBalance() public view returns(uint)  //balance only get manager address only
    {
        require(msg.sender==manager);
        return address(this).balance;
    }

    function random() public view returns(uint) //generating random paricipants address , note: this random method is not applicable in real projects this is just for testing project
    {
        return  uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    function selectWinner() public {  //selecting winner and sending winning balance
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();
        address payable winner;
        uint index = r % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);  //setting participants to new for next round
    }
}