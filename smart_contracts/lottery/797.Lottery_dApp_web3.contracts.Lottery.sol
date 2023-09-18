// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    address payable[] public players;
    address manager;
    address payable public winner;

    constructor(){
        manager = msg.sender;

    }

    receive() external payable{
         require(msg.value == 1 ether,"please pay 1 ether");
         players.push(payable(msg.sender));

    }
function getBalance() public view returns(uint){

require(manager==msg.sender,"You are not the manager");
return address(this).balance;

}

function random() internal view returns(uint){

   return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
}

function pickWinner() public{
    require(msg.sender==manager,"you are not the manager");
    require(players.length>=3,"players are less than 3");


    uint r = random();

    uint index = r%players.length;

    winner = players[index];
    winner.transfer(getBalance());
    players= new address payable[](0);


}


function allPlayers() public view returns (address payable[] memory){
    return players;
}


}

// > contract address:    0x8b1de630b363aA58c6303723D4F3c5DEc496273D


// ganche  0xF78dfA45E43ed1Bd2Abc5CC1B6C291Ee123bA1ba

//0x3163B28AE004475aBE69f4a78E8056657196FF0F