// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 <0.9.0 ;
contract APP
{
    address public manager;// strore the address of the manager
    address payable  []  public  players;//store the adress of all participant who have brought lottery

    constructor()
    {
        manager=msg.sender;// who ever deploy the contract become manager

    }
    //function used to pay ether to the contract from participants
    function recieve() public payable
    {
        require(msg.value==2 ether);
        players.push(payable(msg.sender)); 
    }
    //function by which manger can see the balance
    function getBalance() public view returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }
    //random function
    function random() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    //picking winner
    function Winner() public 
    {
        require(msg.sender==manager);
        require(players.length>=3);//setting minimum requirement of players
        uint r=random();
        uint index=r%players.length;
        address payable  winner;
        winner=players[index];//index of winner
        winner.transfer(getBalance());//sending ether
        players=new address payable [](0);//initializing the player array  lenght to 0;
        

    }
}