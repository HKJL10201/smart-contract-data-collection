// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.9;

contract Lottery {

    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {

        // requires a minimum amount of ether to join the pool
        require(msg.value > .01 ether); 

        players.push(msg.sender); //add player to pool
    }

    function random() private view returns (uint) { // this is just for testing purposes. DO NOT USE THIS IN PRODUCTION.
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {


        uint index = random() % players.length;

        address winner = players[index];
 

        payable(winner).transfer(address(this).balance); // send winner pool money


        // reset pool state
        players = new address[](0); // new dynamic array

    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

}
