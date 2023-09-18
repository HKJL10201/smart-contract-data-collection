// SPDX-License-Identifier: MIT
import "hardhat/console.sol";
pragma solidity ^0.8.18;

contract Voting {
    event VoteValid(bool validVote, address sender, uint candidateNum);
    event Results(bool validVote, address sender, uint candidateWinner);
    uint [4] public canditateArray = [0,0,0,0];
    uint public timeStart;
    uint public timeEnd;

    constructor() {
        timeStart = 1688755964; // 1:13:44 2023-07-07
        timeEnd = 1686166244; // 2:10:44 2023-07-07

    }

    function isTimeValid() public view returns (bool) {
        uint timeNow = block.timestamp;
        console.log(timeNow);
        if (block.timestamp > timeStart && block.timestamp < timeEnd){
            return true;
        }else{
            return true;
        }
     }

    function vote(uint candidateNum) public returns (bool) {
        if (isTimeValid()) {
            uint valueVote = canditateArray[candidateNum] + 1;
            canditateArray[candidateNum] = valueVote;
            console.log(canditateArray[candidateNum]);
            return true;
        } else {
            return false;
        }
    }

    function getWinner() public view returns(uint){
        uint winner = 2;
        for (uint i=0; i <3; i++ ){
            if(canditateArray[i] > canditateArray[i+1]){
               winner = i;
            }else{
                winner = i+1;
            }
        }

        return winner;
    }

}