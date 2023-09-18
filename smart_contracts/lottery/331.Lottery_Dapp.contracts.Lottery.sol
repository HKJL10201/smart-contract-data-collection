// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 <0.9.0 ;

contract Lottery{
    address public manager;
    address payable [] public participants;
    address payable public winner;
    constructor()
    {
        manager=msg.sender; //global variable
    }
    receive() external payable{
        require(msg.value==1 ether);
        participants.push(payable(msg.sender));
    }
    function getBalance() public view returns(uint)
    {
        require(msg.sender == manager,"You are not the manager");
        return address(this).balance;
    }
    function noOfParticipants() public view returns(uint)
    {
        return participants.length;
    }
    function random() public view returns(uint)
    {
       return(uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length))));
    } 
    function selectWinner() public
    {
        require(msg.sender == manager,"You are not the manager");
        require(participants.length>=3,"Players are less than 3");
        uint r = random();
        uint index = r % participants.length;
       // address payable winner; 
        winner = participants[index];
      //  uint rec = participants.length;
        winner.transfer(getBalance()-1500000000000000000);
        participants = new address payable[](0);
        //return winner;
     }
     function allPlayers() public view returns(address payable[] memory)
     {
         return participants;
     }
}
