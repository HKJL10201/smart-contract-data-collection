// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract ElectionsWinner{
    address public owner;
    uint public winnerIndex;
    constructor (){
        owner = msg.sender;
    }
    function getWinnerIndex(uint[] memory tempVotes) public {
        winnerIndex=0;
        uint winningVotes = 0;
        for (uint index = 0; index < tempVotes.length; index++) {
            if (tempVotes[index] > winningVotes) {
                winningVotes = tempVotes[index];
                winnerIndex = index;
            }
        }
    }
}