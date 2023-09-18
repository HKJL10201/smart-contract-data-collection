// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery{
    address public manager;
    address payable[] public participants;

    constructor(){
        manager=msg.sender; 
    }

    /* have not used function keyword for this */
    receive() external payable{
        participants.push(payable(msg.sender));
    }
    /* external fun() can be called using this keyword */

    function getBalance() public view returns(uint){
        require(msg.sender==manager, "Only Manager can check the collected Amount");
        return address(this).balance;
    }
    
    function generateRandom() public view returns(uint){
        /* using algo */ /* generates hashingValue */ /*  */
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function selectWinner() public{
        require(msg.sender==manager, "Only manager can select the winner");
        require(participants.length>=3, "koi participant ta hove");
        uint random = generateRandom();
        uint index= random % participants.length;
        address payable winner= participants[index];
        winner.transfer(getBalance());
        participants= new address payable[](0);
    }
}
