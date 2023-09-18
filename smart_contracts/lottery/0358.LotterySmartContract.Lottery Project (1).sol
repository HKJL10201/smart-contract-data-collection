// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery{

    address public Manager;
    address payable[] Participants;

    constructor() {
        Manager=(msg.sender);
    }    
    function AlreadyExistParticipants() private view returns(bool) {
        for (uint i;i < Participants.length; i++)
        {
            if (Participants[i]==msg.sender)
            return true;
        }
        return false;
    }
    //This function is for applying for lottery
    function ApplyForLottery() public payable {
        require(msg.sender != Manager,"Manager Cannot Apply For Lottery");
        require(AlreadyExistParticipants() == false,"You Already Applied For Lottery");
        require(msg.value >= 1 ether,"Minimum Amount Must Be Payed 1 ether");

        Participants.push(payable(msg.sender));
    } 

    function random() private view returns(uint) {
        return uint(sha256(abi.encodePacked(block.difficulty,block.number,Participants)));
    }

     // Variables for getting value for function-WINNER_IS()
    bool Winner;
    address Winner_Address;

    //This function is only call by manager to Pick Winner Randomly
    function PickWinner() public{
        require(msg.sender==Manager,"Only Manager Can Choose Winner");        
        address ContractAddress = address(this);
        uint index=random()%Participants.length;//Winner Index
        Participants[index].transfer(ContractAddress.balance);
        Winner_Address=Participants[index];
        Winner=true;
        Participants = new address payable[](0);
    }
    //This function is to view that how many and who is applied for this Lottery
    function getParticipants() public view returns(uint,address payable[] memory){
        return (Participants.length,Participants);
    }
    //This Function is to View that who is the winner of this Lottery participants
    function WINNER_IS() public view returns(address){
        require(Winner != false,"Winner is not selected");
        return (Winner_Address);
    }
}


