// SPDX-License-Identifier: MIT
pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() cannotBeManager mustPayEntry public payable {
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public mustBeManager {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier mustBeManager {
        require(msg.sender == manager);
        _;
    }
    
    modifier cannotBeManager {
        require(msg.sender != manager);
        _;
    }
    
    modifier mustPayEntry {
        require(msg.value > .01 ether);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}   