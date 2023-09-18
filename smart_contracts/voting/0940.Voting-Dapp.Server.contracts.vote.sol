//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract vote{
    uint[3] public arr = [0,0,0];   

    function giveVote(uint index) public{
        arr[index]++;
    }

    function returnVote(uint index) public view returns(uint){
        return arr[index];
    }
    function getWinner() public view returns(uint){
        uint maxi = 0;
        uint ind = 0;
        for(uint i = 0; i < arr.length; i++){
            if(arr[i]>maxi){
                maxi = arr[i];
                ind = i;
            }
        }
        return ind;
    }

}