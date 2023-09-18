/*LOTTERY SMART CONTRACT*/

/*

global variavles: owner players
functions: enter lottery , pick winner , get random number
(optional) get pot balance get players others

*/
//solidity version
pragma solidity ^0.8.7;

contract Lottery{
//global variables
address public owner;
address payable[] internal players; 
uint public lotteryId;
mapping(uint => address payable) private lotteryHistory;

constructor(){
//save the owner
owner=msg.sender;
//lottery id
lotteryId=1;
}
//get the winner by lotteryId
function getWinnerByLottery(uint _lotteryId) public view returns (address payable){
    return lotteryHistory[_lotteryId];
}

//the balance
function getBalance() public view returns (uint) {
    return address(this).balance;
}
//function that gets the players
function getPlayers() public view returns (address payable[] memory){
    return players;
}

//functions
//func to enter in the game
function enter() public payable {
    //make the sender send atleast 10 ether
    require(msg.value >= 0.001 ether,"You need atleast 0.001 eth to enter the lottery");
    //add the address to the array (we need to make a cast for it to be payable);
    players.push(payable(msg.sender));
}

//get random number func
function getRandomNumber() internal view returns(uint){
    //uint catch , then hash an concatenation of 2 strings (address and timestamp)
    return uint(keccak256(abi.encodePacked(owner,block.timestamp)));
}

//funcion pickwinner which is public but with onlyOwner modifier created down
function pickwinner() public onlyOwner {
    //require
    require(msg.sender == owner , "You are not allowed to evoque this method");
    //get index
    uint index = getRandomNumber() % players.length;
    //transfer the money to that random number
    players[index].transfer(address(this).balance);
    //lottery history
    lotteryHistory[lotteryId] = players[index];
    //increment lotteryId
    lotteryId++;
    //reset the state of the contract
    players = new address payable[](0);
}

//for code reuse we can create an modifier ,which can represent an certain rules for a certain function
modifier onlyOwner(){
    //require
    require(msg.sender == owner);
    //saying that whatever the code that implements this will implement what is below
    _;
}





}