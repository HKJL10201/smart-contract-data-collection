// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;

    

    constructor() {
        manager = msg.sender;
    }
    function getPlayers() public view returns(address[] memory){
        return players;
    }
    function enter() public payable{
        require(msg.value >= .01 ether);

        players.push((msg.sender));
    }
    function random() private restricted view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,players)));
    }
    function pickWinner() public restricted{
        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(address(this).balance);
        lastWinner = players[index];
        players = new address[](0);
    }
    function getBalance() public restricted view returns(uint) {
        return address(this).balance;
    }
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
}