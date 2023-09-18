// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract lottery {
    address public manager;
    address[] public players;

    constructor (){
        manager = msg.sender;
    }
    function enter() public payable{
        require(msg.value > 0.01 ether,"lottery: you need to send funds more than 0.01 ether to enter the lottery");

        players.push(msg.sender);
    }
    function random() private view returns(uint256){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players )));
    }
    function pickWinner() public restricted {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);

    }
    modifier restricted(){
        require(msg.sender == manager,"lottery: Only manager is allowed");
        _;
    }

    function getPlayers() public view returns(address[] memory){
        return players;
    }
}