//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Lottery{
    //creating a coustom modifire..
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;  //this statement means to whichever fucntion this modifire will bw applied it will run only after the require statement.
    }
    address public owner;
    address payable[] public players;
    uint public LotteryId;
     mapping (uint => address payable) public lotteryHistory;
    constructor(){
        owner = msg.sender;
        LotteryId = 1;
    }
     function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }
    function getBalance()public view returns(uint){
        return address(this).balance;
    }
    function getPlayers()public view returns(address payable[]memory){
        //memory keyword:that this is stored temporarily during this function call
        return players;
    }
    //the function for players entering the lottery..
    function enter() public payable{
        require(msg.value > .01 ether);
        //here msg.sender is actualy the address of the player/ adress invoking the function
        //to store the actual paybale address we use the payable keyword...
        players.push(payable(msg.sender));
    }
    //basicaly its not a pure random number its a kind of psudo-random number:it can be pridicted in a way..
    function getrandomnumber()public view returns (uint){
        return uint(keccak256(abi.encodePacked(owner , block.timestamp)));
    }
     function winner()public onlyOwner{
         //giving a random number between 0 and -1(length of the array)..
        uint index = getrandomnumber() % players.length;
        players[index].transfer(address(this).balance);
         lotteryHistory[LotteryId] = players[index];
        LotteryId++;
        //now to reset the state of the smart contract for the next round
        players = new address payable[](0);
    }
}
