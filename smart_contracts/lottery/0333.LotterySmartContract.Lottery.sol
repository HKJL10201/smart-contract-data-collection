// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//import "hardhat/console.sol";
contract Lottery{
    address public Lottery_manager;
    address[] public participants;
    uint public total_participants;
    uint public price_pool;
    address public winner;
    

constructor () {
    Lottery_manager=msg.sender;
    //console.log("Welcome to Decentralised Lottery System, Good Luck ");
}

modifier owneronly(){
    require(msg.sender==Lottery_manager);
_;
}


function join()public payable{
    require(msg.value>=0.1 ether,"Insufficient balance to enter this Lottery contest");
    participants.push(msg.sender);
    total_participants+=1;
    price_pool+=msg.value;
}

function getRandomNumber() private  view returns(uint){
        return uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number)))%participants.length;
    }

function pickWinner()public owneronly   {
    require(participants.length>0,"No participants available");
    uint index=getRandomNumber();
    payable(participants[index]).transfer(price_pool*3/4);
    winner=participants[index];
    delete participants;
    total_participants = 0;
    price_pool = 0;
}
function getPlayers() public view returns(address [] memory) {
        return participants;
    }

}