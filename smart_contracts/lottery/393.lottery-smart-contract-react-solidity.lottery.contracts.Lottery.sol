// SPDX-License-Identifier: Just want to ignore the warnnig
pragma solidity ^0.7.4;

contract Lottery {
    address public manager;
    address public lastWinner;
    // Must be payable because the method "transfer" or "send" is used on the array elements.
    address payable[] public players;
    string store = "abcdef";
    
    constructor() { 
        // msg is a global variable that contains: data, gas, sender, value.
        manager = msg.sender;
    }
    
    function getPlayerCount() public view returns(uint) {
        return players.length;
    }
    
    function enter() public payable {
        // require is a global function.
        // if require is passed in a falsie value then the function will automatically exit.
        // need to add: require(msg.value = ticketPrice);
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function getStore() public view returns (string memory) {
        return store;
    }
    
    // view because this function will not tempt to change any of the data stored in the contract.
    function random() private view returns (uint) { // uint = uint256
        // sha3 is a global function.
        // block and now (giving the curernt time) are global variable.
        // on solidity >= 0.5.0, The functions .call(), .delegatecall(), staticcall(), keccak256(),
        // sha256() and ripemd160() now accept only a single bytes argument.
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }
    
    function pickWinner() public restricted {
        // Assures us that the number will be in the range of the indexes of the players in the array.
        uint index = random() % players.length;
        // Transfer the amount to the winner.
        players[index].transfer(address(this).balance);
        lastWinner = players[index];
        // We want to create a dynamic array with initial size of 0.
        // So that the lottery will be held over and over.
        players = new address payable[](0);
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    // return the players
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    
    // this function is automatically genereted when we declering an array
    //function getPlayerAtIndex(uint index) public view returns(address player) {
      //  return players[index];
    //}
}