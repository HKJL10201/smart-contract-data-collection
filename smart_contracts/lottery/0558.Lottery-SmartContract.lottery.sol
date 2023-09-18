//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract lottery{

    // Variables for main entities of lottery( address type since it stores address of entity)
    address public manager;
    address payable[] public participants; //payable since we have to pay the winner and array for multiple participants


    //constructor to assign contract address to manager at deploy so it becomes the owner
    constructor()
    {

        manager=msg.sender; //deployer becomes manager of contract
    }


    //receive function used to receive ether (can only be used once in contract)
    receive() external payable
    {
        require(msg.value==1 ether);//condition for buying lottery
        participants.push(payable(msg.sender)); //storing addresses of participants when they send ether
    }

    // function to check total balance
    function getBalance() public view returns(uint)
    {
        require(msg.sender==manager); //only manager can check total balance
        return address(this).balance;
    }

    //function to generate a random number
    function random() public view returns(uint){

        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length))); //keccak256 is hashing algo

    }

    //function to select a winner using random() function call
    function selectWinner() public  
    {

        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();
        address payable winner;
        uint index = r% participants.length;
        winner=participants[index];
        winner.transfer(getBalance());
        participants=new address payable[](0); //reseting participants dynamic array after a round of lottery 
    }











}
