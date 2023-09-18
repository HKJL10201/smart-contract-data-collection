// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Lottery {
    address public owner;
    address payable[] public players; //address for each player that can recieve a payment hence the payable modifier
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;//history of lottery games


constructor(){
    owner = msg.sender; //person who deployed contract
    lotteryId = 1;
}
function getWinnerbyLottery(uint lottery) public view returns(address payable){
    return lotteryHistory[lottery];
}
function getBalance() public view returns(uint){
 return address(this).balance;
}
function getPlayers() public view returns (address payable[] memory){
    return players;
}
//takes in money
function enter() public payable {
    require(msg.value > .01 ether); //defining requried entry payment to lottery

    players.push(payable(msg.sender)); // address of person joining lottery - because they invoked enter function
    //turning address of person into a payable address and adding it into payable array - because each person can get money (is payable)
}

//sudo random algorithm for getting random lottery number
//view because it only reads blockchain data
function getRandomNumber() public view returns (uint)
{
    //abi concatenates two strings in solidity
    return uint(keccak256(abi.encodePacked(owner,block.timestamp)));
}

function pickWinner() public onlyOwner{
    
    uint index = getRandomNumber() % players.length;
    //choose indices of array randomnly
    players[index].transfer(address(this).balance); // transfering total balance of contract

    //For security reasons and of reentry attack, state is updated after transfer
    lotteryHistory[lotteryId] = players[index];
    lotteryId++;
    //updating lotteryhistory map
    //Reseting state of contract
    players = new address payable[](0);
}

modifier onlyOwner() {
require(msg.sender == owner);
_; // run function code after require
}


}
