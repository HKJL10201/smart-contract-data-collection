//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

//creating a contract for lottery

contract Lottery{
    mapping(uint =>address) members;
    uint maxAddresses;
    uint public count;
    uint public rand;
    uint public contractBalance;
    //address payable manager;

    //constructor to intializing the state variables
    constructor(uint _count){
        maxAddresses=_count;
        rand=_count+1;
        //manager=payable(msg.sender);
    }

    //function to get current address
    //bet 30 wei per head
    function getAddresses() public payable {
        require(count < maxAddresses,"pool saturated");
        require(msg.value == 30 wei,"not qualified");
        count+=1;
        members[count]=msg.sender;
       // require(members[count]!=address(0));
        
    }

    //function to get the random number 
    function getRandomNumber(uint _mod)public{
        rand=random(_mod);
        while(rand<=0){
            rand=random(_mod);
        }
        
    }

    //returning the lottery winner
    function lotteryWinner() public returns(address ){

        address payable winner = payable(members[rand]);
        contractBalance=address(this).balance; 
        winner.transfer(address(this).balance);
        return winner;
    }

    
    //here using the random function to generate the random number
    function random(uint mod) private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,msg.sender)))%mod;
    }
}