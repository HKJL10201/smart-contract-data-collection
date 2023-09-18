//SPDX-License-Identifier:GPL-3.0;

pragma solidity 0.8.7;


contract Lottery{
    address public Manager ;
    address payable[] public Players;

    //jab array me br br koi cheez dalny pr gas chahye to hm payable ko array me convert karain gy

    constructor(){
         Manager = msg.sender;
    }
    
    function AlreadyEntered() view private returns(bool){
        for(uint i = 0 ; i < Players.length ; i++){
            if(Players[i] == msg.sender)
                return true;
            }
            return false;
        }

          function Addplayer() public payable{
        require(msg.sender !=  Manager,"MANAGER CAN'T PARTTICIPATE");
        require(AlreadyEntered() == false,"already a participant");
        //jab b function ko require me use karain gy to () ka use lazmi hai
        require(msg.value == 3 ether,"Atleast pay Minimum Amount");
        Players.push(payable(msg.sender));
    }

    function RandomUint() view private returns (uint){
        return uint(sha256(abi.encodePacked(block.difficulty,block.number,Players)));
    }

    function PickWinner() payable public{
        require(msg.sender == Manager);
        uint index = RandomUint()%Players.length;
        address contractAddress = address(this);
        Players[index].transfer(contractAddress.balance);
        Players = new address payable[](0);
    }
 
      

}
    

  
 