// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address payable public manager;
    address payable[] public players;
    address public lastWinner;
    
    constructor() {
        manager = payable(msg.sender);
    }
    
    function enter() public payable {
        require(msg.value == .01 ether);
        players.push(payable(msg.sender));
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        uint pot = (address(this).balance);
        uint fee = pot / 10;
        uint winnings = pot - fee;
        players[index].transfer(winnings);
        manager.transfer(fee);
        lastWinner = players[index];
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getWinner() public view returns(address) {
        return lastWinner;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

}