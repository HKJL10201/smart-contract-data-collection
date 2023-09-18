//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.5.99 <0.8.0;

contract Lottery{
    
    // To make sure only owner(deployer) organizes the program.
    address payable owner;
    
    // Holds list of all the participants who take participate in Lottery.
    address payable[] Participants;
    uint[] Participants_num;
    //mapping (address=>uint) list;
    constructor (){
        owner=msg.sender;   // makes the contract deployer the owner.
    }
    
    // Prevents Owner from participating.
       modifier noOwner(){
        require(msg.sender != owner);
        _;
    }
    
    //Lucky draw wont happen if no one participated.
    modifier empty{
       require(Participants.length>0);
       _;
    }
    
    //Minimum fee requirement
    modifier fee{
        require(msg.value >= 2 ether);
        _;
    }
   
    // This function checks if the people wanting to participate has enough amount to buy or not. If yes, registers them in participant array.
    function Participate(uint Lucky_Num) public payable noOwner fee{
            Participants.push(msg.sender);
            Participants_num.push(Lucky_Num);
            
    }
    
    
    //Gives the list of all Participants kept in address array Participants.
    function Participants_list() public view returns(address payable[] memory){
        return Participants;
    }
    
    // Random number generator, generates using Difficulty of block, Timestamp at contract creation and Particiants value. Firstly 256 hash using Keccack was generated and then was converted into uint.
    function Random() private view returns(uint){
        return uint(keccak256(abi.encode(block.timestamp,block.difficulty,Participants)));
    }
    
    
    // Makes sure only owner can generate winner.
    modifier onlyOwner() {
        require(owner==msg.sender);
        _;
    }
    
    
    // Chooses winner from the list based on their registration index and returns all ether back to winner.
    function winner() public payable onlyOwner empty {
        uint ran = Random()%Participants.length;
        Participants[ran].transfer(address(this).balance);
    }
    
    
}