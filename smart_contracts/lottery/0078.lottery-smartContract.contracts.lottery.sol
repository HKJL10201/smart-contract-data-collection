// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Lottery{
    address  manager ;
    address payable[] players;
    constructor(){
        manager = msg.sender;
    }


    //register player
    function enter() public payable{
        require(msg.sender !=manager,"Manager can't enter");
        require(alreadyEntered()==false,"Player already registered");
        require(msg.value>=1 ether,"Minimum amount must be payed");
        players.push(payable(msg.sender));
    }

    //checking participant exist or not
    function alreadyEntered() private view returns (bool)
    {
        for(uint i=0; i<players.length; i++)
        {
            if(players[i]==msg.sender)
             return true;
        }
        return false;
    }

  //winner index
    function findWinnerIndex() private view returns(uint) {
     return uint(keccak256(abi.encodePacked(block.difficulty, players))) %players.length;
    }

    //translfer money to winner account
    function pickWinner() public 
    {
        require(msg.sender==manager,"Unauthorized Person. Only manager can pick winner.");
        uint winnerIndex = findWinnerIndex();
        players[winnerIndex].transfer(address(this).balance);
        delete players;
    }

    //see participant
    function showPlayer() view public returns (address payable [] memory ){
        return players;
    }





}